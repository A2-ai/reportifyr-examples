# ------------------------------------------------------------------------------
# XYZ-101: flextable versions of the tblkit tables, for timing on dev
#
# Writes flextable copies of the three tables 01-analysis.R authors with
# tblkit, under the same file names, so the shell and 03-build-report.R work
# unchanged:
#   xyz101-demographics.rds   T1 demographics          8 x 7
#   xyz101-nca-summary.rds    T2 NCA summary by cohort 36 x 6
#   xyz101-mean-conc.rds      T4 mean conc by time     4 x 13
#
# The other two tables need no flextable copy: on dev, add_tables() formats a
# data frame (xyz101-power-model.rds, xyz101-nca-individual.csv) with
# format_flextable(), so 01-analysis.R's files serve both branches.
#
# The simulation is copied from 01-analysis.R (same seed, same order), so
# the data are identical. Each table is built to match its tblkit version:
# the same text and number formats, format_flextable()'s look (the
# counterpart of format_table()), the same column widths, and the table
# centered at a fixed layout.
#
# Run after 01-analysis.R; this overwrites the three tblkit .rds files.
#   Rscript scripts/01b-flextable-tables.R
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Load libraries and data
# ------------------------------------------------------------------------------
source(here::here("scripts", "01_analysis", "functions.R"))

library(reportifyr)
library(flextable)
library(dplyr)
library(tidyr)

# ------------------------------------------------------------------------------
# Set paths and fetch meta args
# ------------------------------------------------------------------------------
tables_path <- here::here("OUTPUTS", "tables")
standard_footnotes <- here::here("report", "standard_footnotes.yaml")
config <- here::here("report", "config.yaml")

meta_abbrevs <- get_meta_abbrevs(path_to_footnotes_yaml = standard_footnotes)

# ------------------------------------------------------------------------------
# Simulate the study
#   4 cohorts (100, 200, 400, 800 mg), 10 subjects each, single oral dose,
#   12 samples over 48 h. CL/F scales with weight and CrCL; bioavailability
#   drops 15% at 800 mg so the dose-proportionality assessment has something
#   to find. CL_F and V_F are the apparent values at full bioavailability.
# ------------------------------------------------------------------------------
set.seed(20261123)

doses <- c(100, 200, 400, 800)
n_per_cohort <- 10
nominal_times <- c(0, 0.5, 1, 2, 3, 4, 6, 8, 12, 24, 36, 48)
lloq <- 5 # ng/mL

subjects <- tibble(
  Subject = sprintf("%03d", seq_len(length(doses) * n_per_cohort)),
  Dose = rep(doses, each = n_per_cohort),
  AGE = round(runif(length(Dose), 19, 55)),
  SEX = sample(c("Female", "Male"), length(Dose), replace = TRUE),
  WT = round(pmin(pmax(rnorm(length(Dose), 76, 12), 50), 110), 1),
  CRCL = round(pmin(pmax(rnorm(length(Dose), 105, 20), 60), 150))
) %>%
  mutate(
    Cohort = factor(paste(Dose, "mg"), levels = paste(doses, "mg")),
    F_rel = if_else(Dose == 800, 0.85, 1),
    CL_F = 3.5 * (WT / 70)^0.75 * (CRCL / 100)^0.4 * exp(rnorm(n(), 0, 0.30)),
    V_F = 40 * (WT / 70) * exp(rnorm(n(), 0, 0.20)),
    KA = 1.2 * exp(rnorm(n(), 0, 0.40))
  )

conc_data <- subjects %>%
  crossing(NTIME = nominal_times) %>%
  mutate(
    TIME = if_else(NTIME == 0, 0, NTIME * exp(rnorm(n(), 0, 0.03))),
    IPRED = conc_1cmt_oral(TIME, Dose * F_rel, CL_F, V_F, KA),
    DV = IPRED * exp(rnorm(n(), 0, 0.15)),
    BLQ = DV < lloq,
    DV = if_else(BLQ, NA_real_, DV)
  ) %>%
  arrange(Subject, TIME)

# ------------------------------------------------------------------------------
# Noncompartmental analysis
# ------------------------------------------------------------------------------
nca <- conc_data %>%
  group_by(Subject, Cohort, Dose, WT, CRCL) %>%
  group_modify(~ nca_subject(.x$TIME, .x$NTIME, .x$DV, .y$Dose)) %>%
  ungroup()

# ------------------------------------------------------------------------------
# Table data (as in 01-analysis.R)
# ------------------------------------------------------------------------------
cohort_n <- subjects %>% count(Cohort)
cohort_labels <- c(
  setNames(
    paste0(cohort_n$Cohort, " (N = ", cohort_n$n, ")"),
    as.character(cohort_n$Cohort)
  ),
  Overall = paste0("Overall (N = ", nrow(subjects), ")")
)

demog_by <- function(d) {
  n <- nrow(d)
  tibble(
    characteristic = c(
      rep("Age (years)", 2), rep("Weight (kg)", 2),
      rep("CrCL (mL/min)", 2), rep("Sex, n (%)", 2)
    ),
    stat = c(rep(c("Mean (SD)", "Median [Min, Max]"), 3), "Female", "Male"),
    value = c(
      fmt_mean_sd(d$AGE), fmt_median_range(d$AGE, 0),
      fmt_mean_sd(d$WT), fmt_median_range(d$WT),
      fmt_mean_sd(d$CRCL), fmt_median_range(d$CRCL, 0),
      fmt_n_pct(sum(d$SEX == "Female"), n), fmt_n_pct(sum(d$SEX == "Male"), n)
    )
  )
}

demog_long <- bind_rows(
  subjects %>%
    group_by(cohort = as.character(Cohort)) %>%
    group_modify(~ demog_by(.x)) %>%
    ungroup(),
  demog_by(subjects) %>% mutate(cohort = "Overall")
)

param_cols <- c("Cmax", "Tmax", "AUC_0_24", "AUC_0_inf", "Half_life", "CL_F")

nca_summary <- nca %>%
  select(Cohort, all_of(param_cols)) %>%
  pivot_longer(-Cohort, names_to = "param", values_to = "x") %>%
  group_by(cohort = as.character(Cohort), param) %>%
  summarise(
    n = n(),
    Mean = mean(x),
    SD = sd(x),
    `CV%` = 100 * sd(x) / mean(x),
    `Geo. mean` = geo_mean(x),
    Median = median(x),
    Min = min(x),
    Max = max(x),
    .groups = "drop"
  ) %>%
  pivot_longer(-c(cohort, param), names_to = "stat", values_to = "value")

mean_conc <- conc_data %>%
  group_by(cohort = as.character(Cohort), time = as.character(NTIME)) %>%
  summarise(
    value = if (all(BLQ)) NA_real_ else mean(DV, na.rm = TRUE),
    status = if (all(BLQ)) "BLQ" else "ok",
    .groups = "drop"
  )

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------

# Significant figures as tblkit's tk_format(sig =) writes them: trailing
# zeros kept (25.0), no scientific notation (1330).
fmt_sig <- function(x, sig = 3) {
  digits <- pmax(sig - 1 - floor(log10(abs(x))), 0)
  digits[!is.finite(digits)] <- 0
  vapply(
    seq_along(x),
    function(i) formatC(signif(x[i], sig), format = "f", digits = digits[i]),
    character(1)
  )
}

# format_flextable()'s look, then the tblkit table's column widths and
# placement (fixed widths, centered).
finish <- function(ft, widths) {
  ft |>
    format_flextable() |>
    width(width = widths) |>
    set_table_properties(layout = "fixed", align = "center")
}

cohorts <- levels(subjects$Cohort)

# ------------------------------------------------------------------------------
# T1: demographics by cohort
# ------------------------------------------------------------------------------
t1_wide <- demog_long |>
  pivot_wider(names_from = cohort, values_from = value) |>
  select(characteristic, stat, all_of(names(cohort_labels)))

t1_demographics <- flextable(t1_wide) |>
  set_header_labels(
    values = c(
      characteristic = "Characteristic",
      stat = "Statistic",
      as.list(cohort_labels)
    )
  ) |>
  merge_v(j = "characteristic") |>
  valign(j = "characteristic", valign = "top", part = "body") |>
  finish(widths = c(1.05, 1.25, rep(0.74, length(cohort_labels))))

save_rds_with_metadata(
  object = t1_demographics,
  file = file.path(tables_path, "xyz101-demographics.rds"),
  config_yaml = config,
  meta_notes = "CrCL was estimated with the Cockcroft-Gault equation.",
  meta_abbrevs = c(meta_abbrevs$CrCL, meta_abbrevs$SD)
)

# ------------------------------------------------------------------------------
# T2: summary NCA parameters by cohort
# ------------------------------------------------------------------------------
stat_order <- c("n", "Mean (SD)", "CV%", "Geo. mean", "Median", "Min, Max")

t2_wide <- nca_summary |>
  pivot_wider(names_from = stat, values_from = value) |>
  transmute(
    param,
    cohort,
    n = sprintf("%.0f", n),
    `Mean (SD)` = paste0(fmt_sig(Mean), " (", fmt_sig(SD), ")"),
    `CV%` = sprintf("%.1f", `CV%`),
    `Geo. mean` = fmt_sig(`Geo. mean`),
    Median = fmt_sig(Median),
    `Min, Max` = paste0(fmt_sig(Min), ", ", fmt_sig(Max))
  ) |>
  pivot_longer(all_of(stat_order), names_to = "stat", values_to = "value") |>
  pivot_wider(names_from = cohort, values_from = value) |>
  mutate(
    param = factor(param, levels = param_cols),
    stat = factor(stat, levels = stat_order)
  ) |>
  arrange(param, stat) |>
  mutate(across(c(param, stat), as.character)) |>
  mutate(stat = if_else(stat == "CV%", "CV (%)", stat)) |>
  select(param, stat, all_of(cohorts))

param_label <- function(ft, code, value) {
  compose(ft, i = which(t2_wide$param == code), j = "param", value = value)
}

t2_nca_summary <- flextable(t2_wide) |>
  set_header_labels(
    values = c(
      param = "Parameter",
      stat = "Statistic",
      as.list(cohort_labels[cohorts])
    )
  ) |>
  param_label("Cmax", as_paragraph("C", as_sub("max"), " (ng/mL)")) |>
  param_label("Tmax", as_paragraph("T", as_sub("max"), " (h)")) |>
  param_label("AUC_0_24", as_paragraph("AUC", as_sub("0-24"), " (h·ng/mL)")) |>
  param_label("AUC_0_inf", as_paragraph("AUC", as_sub("0-∞"), " (h·ng/mL)")) |>
  param_label("Half_life", as_paragraph("t", as_sub("1/2"), " (h)")) |>
  param_label("CL_F", as_paragraph("CL/F (L/h)")) |>
  merge_v(j = "param") |>
  valign(j = "param", valign = "top", part = "body") |>
  finish(widths = c(1.5, 1, rep(0.875, length(cohorts))))

save_rds_with_metadata(
  object = t2_nca_summary,
  file = file.path(tables_path, "xyz101-nca-summary.rds"),
  config_yaml = config,
  meta_notes = paste(
    "AUC was calculated with the linear-up/log-down trapezoidal rule.",
    "AUC0-inf was extrapolated from the last measurable sample (up to 48 h) with",
    "the terminal slope estimated from the last three measurable post-peak samples."
  ),
  meta_abbrevs = c(
    meta_abbrevs$`AUC_{0-24}`, meta_abbrevs$`AUC_{0-inf}`, meta_abbrevs$`C_{max}`,
    meta_abbrevs$`T_{max}`, meta_abbrevs$`t_{1/2}`, meta_abbrevs$`CL/F`,
    meta_abbrevs$CV, meta_abbrevs$SD
  )
)

# ------------------------------------------------------------------------------
# T4: mean concentration by nominal time
# ------------------------------------------------------------------------------
times <- as.character(nominal_times)

t4_wide <- mean_conc |>
  mutate(value = if_else(status == "BLQ", "BLQ", fmt_sig(value))) |>
  select(cohort, time, value) |>
  pivot_wider(names_from = time, values_from = value) |>
  mutate(cohort = factor(cohort, levels = cohorts)) |>
  arrange(cohort) |>
  mutate(cohort = as.character(cohort)) |>
  select(cohort, all_of(times))

t4_mean_conc <- flextable(t4_wide) |>
  set_header_labels(values = list(cohort = "Cohort")) |>
  add_header_row(
    values = c("", "Mean concentration (ng/mL) by nominal time post-dose (h)"),
    colwidths = c(1, length(times))
  ) |>
  finish(widths = c(0.72, rep(0.44, length(times)))) |>
  fontsize(size = 9, part = "all") |>
  align(j = times, align = "right", part = "body")

save_rds_with_metadata(
  object = t4_mean_conc,
  file = file.path(tables_path, "xyz101-mean-conc.rds"),
  config_yaml = config,
  meta_notes = paste0(
    "BLQ samples (< ", lloq, " ng/mL) were excluded from the means; ",
    "a time point with all samples BLQ is shown as BLQ."
  ),
  meta_abbrevs = c(meta_abbrevs$BLQ, meta_abbrevs$LLOQ)
)
