# ------------------------------------------------------------------------------
# XYZ-101: single ascending dose pharmacokinetics (simulated)
#
# Produces the report artifacts:
#   5 tables of different shapes (body rows x columns):
#     T3 dose proportionality    3 x 7    tiny             data frame .rds
#     T4 mean conc by time       4 x 13   short and wide   tblkit .rds
#     T1 demographics            8 x 7    short, grouped   tblkit .rds
#     T2 NCA summary by cohort  36 x 6    tall, grouped    tblkit .rds
#     T5 individual NCA         40 x 9    long listing     .csv
#   5 figures (.png)
#
# Tables are authored three ways, one per insertion route in add_tables():
#   tblkit table (tk() + tk_* verbs) saved as .rds -> inserted as authored
#   data frame saved as .rds                        -> format_table()
#   data frame saved as .csv                        -> format_table()
#
# Run from example-report/ (its .Rprofile loads the repo rv library):
#   Rscript scripts/01-analysis.R
# Then doc.R for the report shell, then build.R.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Load functions and libraries
# ------------------------------------------------------------------------------
source(here::here("scripts", "01_analysis", "functions.R"))

library(reportifyr)
library(tblkit)
library(ggplot2)
library(dplyr)
library(tidyr)

# ------------------------------------------------------------------------------
# Initialize report project
# ------------------------------------------------------------------------------
project_dir <- here::here()

initialize_report_project(
  project_dir = project_dir,
  report_dir_name = NULL,
  outputs_dir_name = NULL
)

# ------------------------------------------------------------------------------
# Set paths and fetch meta args
# ------------------------------------------------------------------------------
figures_path <- file.path(project_dir, "OUTPUTS", "figures")
tables_path <- file.path(project_dir, "OUTPUTS", "tables")
standard_footnotes <- file.path(project_dir, "report", "standard_footnotes.yaml")
config <- file.path(project_dir, "report", "config.yaml")

meta_type <- get_meta_type(path_to_footnotes_yaml = standard_footnotes)
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

# ==============================================================================
# TABLES
# ==============================================================================

cohort_n <- subjects %>% count(Cohort)
cohort_labels <- c(
  setNames(
    paste0(cohort_n$Cohort, " (N = ", cohort_n$n, ")"),
    as.character(cohort_n$Cohort)
  ),
  Overall = paste0("Overall (N = ", nrow(subjects), ")")
)

# ------------------------------------------------------------------------------
# T1: demographics by cohort (short x narrow, tblkit table)
# ------------------------------------------------------------------------------
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

t1_demographics <- tk(
  demog_long,
  stub = c("characteristic", "stat"),
  cols = "cohort",
  value = "value"
) |>
  tk_order(characteristic = unique(demog_long$characteristic)) |>
  tk_order(stat = unique(demog_long$stat)) |>
  tk_order(cohort = names(cohort_labels)) |>
  tk_label(characteristic = "Characteristic", stat = "Statistic") |>
  tk_label(cohort = as.list(cohort_labels)) |>
  tk_group("characteristic") |>
  format_table() |>
  tk_layout(widths = c(characteristic = 1.05, stat = 1.25, .default = 0.74))

save_rds_with_metadata(
  object = t1_demographics,
  file = file.path(tables_path, "xyz101-demographics.rds"),
  config_yaml = config,
  meta_notes = "CrCL was estimated with the Cockcroft-Gault equation.",
  meta_abbrevs = c(meta_abbrevs$CrCL, meta_abbrevs$SD)
)

# ------------------------------------------------------------------------------
# T2: summary NCA parameters by cohort (medium, tblkit table)
# ------------------------------------------------------------------------------
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

t2_nca_summary <- tk(
  nca_summary,
  stub = c("param", "stat"),
  cols = "cohort",
  value = "value"
) |>
  tk_order(param = param_cols) |>
  tk_order(cohort = levels(subjects$Cohort)) |>
  tk_format(sig = 3) |>
  tk_format(at_rows("n"), decimals = 0) |>
  tk_format(at_rows("CV%"), decimals = 1) |>
  tk_combine(rows = c("Mean", "SD"), into = "Mean (SD)") |>
  tk_combine(rows = c("Min", "Max"), into = "Min, Max", pattern = "{Min}, {Max}") |>
  tk_label(
    param = list(
      Cmax = tk_text("C~max~ (ng/mL)"),
      Tmax = tk_text("T~max~ (h)"),
      AUC_0_24 = tk_text("AUC~0-24~ (h·ng/mL)"),
      AUC_0_inf = tk_text("AUC~0-∞~ (h·ng/mL)"),
      Half_life = tk_text("t~1/2~ (h)"),
      CL_F = "CL/F (L/h)"
    ),
    stat = c(`CV%` = "CV (%)")
  ) |>
  tk_label(param = "Parameter", stat = "Statistic") |>
  tk_label(cohort = as.list(cohort_labels[levels(subjects$Cohort)])) |>
  tk_group("param") |>
  format_table() |>
  tk_layout(widths = c(param = 1.5, stat = 1, .default = 0.875))

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
# T3: power-model dose proportionality (tiny, data frame .rds)
# ------------------------------------------------------------------------------
t3_power_model <- bind_rows(
  power_model(nca$Cmax, nca$Dose, "Cmax (ng/mL)"),
  power_model(nca$AUC_0_24, nca$Dose, "AUC0-24 (h*ng/mL)"),
  power_model(nca$AUC_0_inf, nca$Dose, "AUC0-inf (h*ng/mL)")
)

save_rds_with_metadata(
  object = t3_power_model,
  file = file.path(tables_path, "xyz101-power-model.rds"),
  config_yaml = config,
  meta_type = meta_type$`linear-regression-fit`,
  meta_notes = paste(
    "Power model: ln(parameter) = a + b * ln(dose).",
    "Acceptance range for b over the 8-fold dose range per Smith et al. (2000),",
    "derived from the 0.80-1.25 equivalence bounds."
  ),
  meta_abbrevs = c(
    meta_abbrevs$`AUC_{0-24}`, meta_abbrevs$`AUC_{0-inf}`,
    meta_abbrevs$`C_{max}`, meta_abbrevs$CI
  )
)

# ------------------------------------------------------------------------------
# T4: mean concentration by nominal time (short x wide, tblkit table)
# ------------------------------------------------------------------------------
mean_conc <- conc_data %>%
  group_by(cohort = as.character(Cohort), time = as.character(NTIME)) %>%
  summarise(
    value = if (all(BLQ)) NA_real_ else mean(DV, na.rm = TRUE),
    status = if (all(BLQ)) "BLQ" else "ok",
    .groups = "drop"
  )

t4_mean_conc <- tk(
  mean_conc,
  stub = "cohort",
  cols = "time",
  value = "value",
  status = "status"
) |>
  tk_order(cohort = levels(subjects$Cohort)) |>
  tk_order(time = as.character(nominal_times)) |>
  tk_format(sig = 3) |>
  tk_label(cohort = "Cohort") |>
  tk_spanner("Mean concentration (ng/mL) by nominal time post-dose (h)",
             as.character(nominal_times)) |>
  format_table() |>
  tk_theme(font_size = 9, value_align = "right") |>
  tk_layout(widths = c(cohort = 0.72, .default = 0.44))

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

# ------------------------------------------------------------------------------
# T5: individual NCA parameter listing (long, .csv -> format_table())
#   Column names stay syntactic: read.csv() would rewrite "AUC0-24 (h*ng/mL)".
#   Units are given in the footnote.
# ------------------------------------------------------------------------------
t5_individual <- nca %>%
  transmute(
    Subject,
    Dose,
    Cmax = signif(Cmax, 3),
    Tmax = round(Tmax, 2),
    AUC0_24 = signif(AUC_0_24, 3),
    AUC0_inf = signif(AUC_0_inf, 3),
    Pct_extrap = round(Pct_extrap, 1),
    Half_life = round(Half_life, 2),
    CL_F = round(CL_F, 2)
  )

write_csv_with_metadata(
  object = t5_individual,
  file = file.path(tables_path, "xyz101-nca-individual.csv"),
  config_yaml = config,
  meta_notes = paste(
    "Units: Dose (mg), Cmax (ng/mL), Tmax (h), AUC0_24 and AUC0_inf (h*ng/mL),",
    "Pct_extrap (% of AUC0_inf extrapolated beyond the last sample), Half_life (h), CL_F (L/h)."
  ),
  meta_abbrevs = c(
    meta_abbrevs$`AUC_{0-24}`, meta_abbrevs$`AUC_{0-inf}`, meta_abbrevs$`C_{max}`,
    meta_abbrevs$`T_{max}`, meta_abbrevs$`t_{1/2}`, meta_abbrevs$`CL/F`
  ),
  row.names = FALSE
)

# ==============================================================================
# FIGURES
# ==============================================================================

cohort_colors <- c(
  "100 mg" = "#2F6DB5", "200 mg" = "#3A9E6F",
  "400 mg" = "#D08A2E", "800 mg" = "#B5403A"
)

# ------------------------------------------------------------------------------
# F1: individual concentration-time profiles, semi-log, by cohort
# ------------------------------------------------------------------------------
f1_individual <- conc_data %>%
  filter(!BLQ) %>%
  ggplot(aes(TIME, DV, group = Subject, color = Cohort)) +
  geom_line(alpha = 0.7) +
  geom_point(size = 0.9) +
  geom_hline(yintercept = lloq, linetype = "dashed", color = "grey40") +
  facet_wrap(~Cohort, nrow = 2) +
  scale_y_log10() +
  scale_x_continuous(breaks = c(0, 12, 24, 36, 48)) +
  scale_color_manual(values = cohort_colors, guide = "none") +
  theme_bw() +
  labs(x = "Time post-dose (h)", y = "Concentration (ng/mL)")

ggsave_with_metadata(
  filename = file.path(figures_path, "xyz101-conc-individual.png"),
  plot = f1_individual,
  meta_type = meta_type$`conc-time-trajectories`,
  meta_notes = paste0(
    "Semi-logarithmic scale. Dashed line is the LLOQ (", lloq,
    " ng/mL); BLQ samples are not shown."
  ),
  meta_abbrevs = c(meta_abbrevs$LLOQ, meta_abbrevs$BLQ),
  height = 5, width = 6
)

# ------------------------------------------------------------------------------
# F2: mean (SD) concentration-time profiles by cohort
# ------------------------------------------------------------------------------
f2_mean <- conc_data %>%
  group_by(Cohort, NTIME) %>%
  summarise(
    mean = mean(DV, na.rm = TRUE),
    sd = sd(DV, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(is.finite(mean)) %>%
  ggplot(aes(NTIME, mean, color = Cohort)) +
  geom_errorbar(aes(ymin = pmax(mean - sd, 0), ymax = mean + sd), width = 0.4) +
  geom_line() +
  geom_point() +
  scale_x_continuous(breaks = c(0, 4, 8, 12, 24, 36, 48)) +
  scale_color_manual(values = cohort_colors) +
  theme_bw() +
  theme(legend.position = "bottom") +
  labs(x = "Nominal time post-dose (h)", y = "Mean (SD) concentration (ng/mL)",
       color = "Dose")

ggsave_with_metadata(
  filename = file.path(figures_path, "xyz101-conc-mean.png"),
  plot = f2_mean,
  meta_notes = "Points are arithmetic means; error bars are +/- 1 SD. BLQ samples were excluded.",
  meta_abbrevs = c(meta_abbrevs$SD, meta_abbrevs$BLQ),
  height = 4, width = 6
)

# ------------------------------------------------------------------------------
# F3: dose proportionality, log-log with power-model fit
# ------------------------------------------------------------------------------
f3_power <- nca %>%
  select(Dose, Cohort, Cmax, AUC_0_inf) %>%
  pivot_longer(c(Cmax, AUC_0_inf), names_to = "param", values_to = "value") %>%
  mutate(param = factor(
    param,
    levels = c("Cmax", "AUC_0_inf"),
    labels = c("Cmax (ng/mL)", "AUC0-inf (h*ng/mL)")
  )) %>%
  ggplot(aes(Dose, value)) +
  geom_point(aes(color = Cohort), alpha = 0.8) +
  geom_smooth(method = "lm", formula = y ~ x, color = "black", linewidth = 0.6) +
  facet_wrap(~param, scales = "free_y") +
  scale_x_log10(breaks = doses) +
  scale_y_log10() +
  scale_color_manual(values = cohort_colors, guide = "none") +
  theme_bw() +
  labs(x = "Dose (mg)", y = "Parameter value")

ggsave_with_metadata(
  filename = file.path(figures_path, "xyz101-dose-proportionality.png"),
  plot = f3_power,
  meta_type = meta_type$`linear-regression-plot`,
  meta_notes = "Both axes are logarithmic; the line is the power-model fit with its 95% CI.",
  meta_abbrevs = c(meta_abbrevs$`C_{max}`, meta_abbrevs$`AUC_{0-inf}`, meta_abbrevs$CI),
  height = 4, width = 6
)

# ------------------------------------------------------------------------------
# F4: dose-normalised exposure by cohort
# ------------------------------------------------------------------------------
f4_dose_norm <- nca %>%
  transmute(
    Cohort,
    `Cmax / Dose` = Cmax / Dose,
    `AUC0-inf / Dose` = AUC_0_inf / Dose
  ) %>%
  pivot_longer(-Cohort, names_to = "param", values_to = "value") %>%
  mutate(param = factor(param, levels = c("Cmax / Dose", "AUC0-inf / Dose"))) %>%
  ggplot(aes(Cohort, value)) +
  geom_boxplot(outlier.shape = NA, fill = "grey92") +
  geom_jitter(aes(color = Cohort), width = 0.15, height = 0, shape = 1) +
  facet_wrap(~param, scales = "free_y") +
  scale_color_manual(values = cohort_colors, guide = "none") +
  theme_bw() +
  labs(x = "Dose cohort", y = "Dose-normalised value (per mg)")

ggsave_with_metadata(
  filename = file.path(figures_path, "xyz101-dose-normalised.png"),
  plot = f4_dose_norm,
  meta_type = meta_type$boxplot,
  meta_notes = "Cmax/Dose in ng/mL/mg; AUC0-inf/Dose in h*ng/mL/mg.",
  meta_abbrevs = c(meta_abbrevs$`C_{max}`, meta_abbrevs$`AUC_{0-inf}`),
  height = 4, width = 6
)

# ------------------------------------------------------------------------------
# F5: CL/F versus body weight and CrCL
# ------------------------------------------------------------------------------
cov_long <- nca %>%
  select(Subject, Cohort, CL_F, WT, CRCL) %>%
  pivot_longer(c(WT, CRCL), names_to = "covariate", values_to = "value") %>%
  mutate(covariate = factor(
    covariate,
    levels = c("WT", "CRCL"),
    labels = c("Body weight (kg)", "CrCL (mL/min)")
  ))

cov_stats <- cov_long %>%
  group_by(covariate) %>%
  summarise(
    label = {
      ct <- cor.test(value, CL_F)
      sprintf("R = %.2f, p = %.3g", ct$estimate, ct$p.value)
    },
    .groups = "drop"
  )

f5_covariates <- ggplot(cov_long, aes(value, CL_F)) +
  geom_point(aes(color = Cohort)) +
  geom_smooth(method = "lm", formula = y ~ x, color = "black", linewidth = 0.6) +
  geom_text(
    data = cov_stats, aes(label = label),
    x = -Inf, y = Inf, hjust = -0.05, vjust = 1.5, size = 3.2, inherit.aes = FALSE
  ) +
  facet_wrap(~covariate, scales = "free_x") +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.15))) +
  scale_color_manual(values = cohort_colors) +
  theme_bw() +
  theme(legend.position = "bottom") +
  labs(x = NULL, y = "CL/F (L/h)", color = "Dose")

ggsave_with_metadata(
  filename = file.path(figures_path, "xyz101-clf-covariates.png"),
  plot = f5_covariates,
  meta_type = meta_type$correlation_plot,
  meta_notes = "Lines are least-squares fits with 95% CI.",
  meta_abbrevs = c(meta_abbrevs$`CL/F`, meta_abbrevs$CrCL, meta_abbrevs$WTBL),
  height = 4, width = 6
)
