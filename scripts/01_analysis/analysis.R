# ------------------------------------------------------------------------------
# Package installation
# ------------------------------------------------------------------------------
# Now handled by rv via CLI

# ------------------------------------------------------------------------------
# Load function and libraries
# ------------------------------------------------------------------------------
source(here::here("scripts", "01_analysis", "function.R"))

library(reportifyr)
library(ggplot2)
library(dplyr)

# ------------------------------------------------------------------------------
# Initialize report project
# ------------------------------------------------------------------------------
initialize_report_project(
  project_dir = here::here(),
  report_dir_name = NULL,
  outputs_dir_name = NULL
)

# ------------------------------------------------------------------------------
# Set paths and fetch meta args
# ------------------------------------------------------------------------------
figures_path <- here::here("OUTPUTS", "figures")
tables_path  <- here::here("OUTPUTS", "tables")
standard_footnotes <- here::here("report", "standard_footnotes.yaml")
config <- here::here("report", "config.yaml")

meta_type <- get_meta_type(path_to_footnotes_yaml = standard_footnotes)
meta_abbrevs <- get_meta_abbrevs(path_to_footnotes_yaml = standard_footnotes)

# ------------------------------------------------------------------------------
# Process data and generate artifacts
# ------------------------------------------------------------------------------
data <- Theoph

pk_params <- data %>%
  mutate(Subject = as.numeric(Subject)) %>%
  group_by(Subject) %>%
  summarise(
    Cmax = max(conc, na.rm = TRUE),
    Tmax = Time[which.max(conc)],
    AUC = calc_auc_linear_log(Time, conc),
    WTBL = Wt %>% unique()
  )

knitr::kable(pk_params)

outfile_name <- "theoph-pk-parameters.csv"

write_csv_with_metadata(
  object = pk_params,
  file = file.path(tables_path, outfile_name),
  config_yaml = config,
  meta_type = meta_type$`parameter-summary`,
  meta_equations = NULL,
  meta_notes = "AUC was calculated using linear trapezoidal integration for ascending and non-loggable segments and log-linear trapezoidal integration for descending segments.",
  meta_abbrevs = c(meta_abbrevs$AUC, meta_abbrevs$`C_{max}`, meta_abbrevs$`T_{max}`, meta_abbrevs$WTBL),
  table1_format = FALSE,
  row.names = FALSE
)

conc <- data %>%
  mutate(Subject = factor(Subject, levels = sort(unique(as.numeric(Subject))))) %>%
  ggplot(aes(x = Time, y = conc, color = Subject)) +
  geom_line() +
  geom_point() +
  theme_bw() +
  labs(x = "Time (hr)", y = "Theophylline Concentration (ng/mL)", color = "Subject ID")

conc

plot_file_name <- "theoph-pk-conc.png"

ggsave_with_metadata(
  filename = file.path(figures_path, plot_file_name),
  plot = conc,
  meta_type = meta_type$`conc-time-trajectories`,
  meta_equations = NULL,
  meta_notes = "Each colored line represents the observed concentration–time profile for a specific subject identifier.",
  meta_abbrevs = c(meta_abbrevs$`C_{max}`, meta_abbrevs$`T_{max}`),
  height = 4,
  width = 6
)

lr <- pk_params %>%
  ggplot(aes(x = WTBL, y = AUC)) +
  geom_point() +
  geom_smooth(method = "lm", formula = y ~ x, se = TRUE, color = "blue") +
  theme_bw() +
  labs(x = "WTBL (kg)", y = "AUC (hr*mg/L)")

lr

plot_file_name <- "theoph-pk-exposure.png"

ggsave_with_metadata(
  filename = file.path(figures_path, plot_file_name),
  plot = lr,
  meta_type = meta_type$`linear-regression-plot`,
  meta_equations = NULL,
  meta_notes = "AUC was calculated using linear trapezoidal integration for ascending and non-loggable segments and log-linear trapezoidal integration for descending segments.",
  meta_abbrevs = c(meta_abbrevs$AUC, meta_abbrevs$WTBL),
  height = 4,
  width = 6
)

# ------------------------------------------------------------------------------
# Additional plots for table cell figure templates
# ------------------------------------------------------------------------------

# 1. Boxplot of Cmax by weight quartile
pk_params_q <- pk_params %>%
  mutate(Wt_quartile = cut(WTBL, breaks = quantile(WTBL, probs = 0:4/4), include.lowest = TRUE, labels = c("Q1", "Q2", "Q3", "Q4")))

boxplot_p <- ggplot(pk_params_q, aes(x = Wt_quartile, y = Cmax)) +
  geom_boxplot() +
  geom_point() +
  theme_bw() +
  labs(x = "Weight Quartile", y = "Cmax (ng/mL)")

ggsave_with_metadata(
  filename = file.path(figures_path, "theoph-pk-boxplot.png"),
  plot = boxplot_p,
  meta_type = meta_type$boxplot,
  meta_equations = NULL,
  meta_notes = "Cmax values grouped by baseline weight quartiles.",
  meta_abbrevs = c(meta_abbrevs$`C_{max}`, meta_abbrevs$WTBL),
  height = 4, width = 6
)

# 2. Residuals from AUC ~ WTBL linear model
fit <- lm(AUC ~ WTBL, data = pk_params)
pk_resid <- pk_params %>% mutate(residuals = residuals(fit), fitted = fitted(fit))

resid_p <- ggplot(pk_resid, aes(x = fitted, y = residuals)) +
  geom_point() +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  theme_bw() +
  labs(x = "Fitted AUC (hr*mg/L)", y = "Residuals")

ggsave_with_metadata(
  filename = file.path(figures_path, "theoph-pk-residuals.png"),
  plot = resid_p,
  meta_type = meta_type$`linear-regression-plot`,
  meta_equations = NULL,
  meta_notes = "Residuals from a linear regression of AUC on baseline weight.",
  meta_abbrevs = c(meta_abbrevs$AUC, meta_abbrevs$WTBL),
  height = 4, width = 6
)

# 3. Histogram of AUC values
hist_p <- ggplot(pk_params, aes(x = AUC)) +
  geom_histogram(bins = 8, fill = "steelblue", color = "white") +
  theme_bw() +
  labs(x = "AUC (hr*mg/L)", y = "Count")

ggsave_with_metadata(
  filename = file.path(figures_path, "theoph-pk-histogram.png"),
  plot = hist_p,
  meta_type = meta_type$`ETA_histogram`,
  meta_equations = NULL,
  meta_notes = "Distribution of individual AUC values across subjects.",
  meta_abbrevs = c(meta_abbrevs$AUC),
  height = 4, width = 6
)

# 4. Tmax vs Cmax scatter
scatter_p <- ggplot(pk_params, aes(x = Tmax, y = Cmax)) +
  geom_point() +
  geom_smooth(method = "lm", formula = y ~ x, se = TRUE, color = "blue") +
  theme_bw() +
  labs(x = "Tmax (hr)", y = "Cmax (ng/mL)")

ggsave_with_metadata(
  filename = file.path(figures_path, "theoph-pk-scatter.png"),
  plot = scatter_p,
  meta_type = meta_type$`correlation_plot`,
  meta_equations = NULL,
  meta_notes = "Relationship between time to peak concentration and peak concentration.",
  meta_abbrevs = c(meta_abbrevs$`C_{max}`, meta_abbrevs$`T_{max}`),
  height = 4, width = 6
)

# 5. Concentration density overlay by subject
density_p <- data %>%
  mutate(Subject = factor(Subject, levels = sort(unique(as.numeric(Subject))))) %>%
  ggplot(aes(x = conc, fill = Subject)) +
  geom_density(alpha = 0.3) +
  theme_bw() +
  labs(x = "Theophylline Concentration (ng/mL)", y = "Density", fill = "Subject ID")

ggsave_with_metadata(
  filename = file.path(figures_path, "theoph-pk-density.png"),
  plot = density_p,
  meta_type = meta_type$`conc-time-trajectories`,
  meta_equations = NULL,
  meta_notes = "Density distributions of observed concentrations by subject.",
  meta_abbrevs = c(meta_abbrevs$`C_{max}`),
  height = 4, width = 6
)

# 6. Bar chart of mean PK parameters
bar_data <- pk_params %>%
  summarise(across(c(Cmax, Tmax, AUC), list(mean = mean, sd = sd))) %>%
  tidyr::pivot_longer(everything(), names_to = c("param", "stat"), names_sep = "_") %>%
  tidyr::pivot_wider(names_from = stat, values_from = value)

bar_p <- ggplot(bar_data, aes(x = param, y = mean)) +
  geom_col(fill = "steelblue") +
  geom_errorbar(aes(ymin = mean - sd, ymax = mean + sd), width = 0.2) +
  theme_bw() +
  labs(x = "Parameter", y = "Mean Value")

ggsave_with_metadata(
  filename = file.path(figures_path, "theoph-pk-bar.png"),
  plot = bar_p,
  meta_type = meta_type$boxplot,
  meta_equations = NULL,
  meta_notes = "Mean pharmacokinetic parameter values with standard deviation error bars.",
  meta_abbrevs = c(meta_abbrevs$AUC, meta_abbrevs$`C_{max}`, meta_abbrevs$`T_{max}`),
  height = 4, width = 6
)

# theoph-pk-line.png — Mean concentration over time
line_p <- data %>%
  group_by(Time) %>%
  summarise(mean_conc = mean(conc), .groups = "drop") %>%
  ggplot(aes(x = Time, y = mean_conc)) +
  geom_line(color = "steelblue", linewidth = 1) +
  geom_point(color = "steelblue") +
  theme_bw() +
  labs(x = "Time (hr)", y = "Mean Concentration (ng/mL)")

ggsave_with_metadata(
  filename = file.path(figures_path, "theoph-pk-line.png"),
  plot = line_p,
  meta_type = meta_type$`conc-time-trajectories`,
  meta_equations = NULL,
  meta_notes = "Mean concentration-time profile across all subjects.",
  meta_abbrevs = c(meta_abbrevs$`C_{max}`, meta_abbrevs$`T_{max}`),
  height = 4, width = 6
)

# theoph-pk-random.png — Random jittered weight vs subject
random_p <- data %>%
  mutate(Subject = factor(Subject, levels = sort(unique(as.numeric(Subject))))) %>%
  ggplot(aes(x = Subject, y = Wt)) +
  geom_jitter(width = 0.2, height = 0, color = "darkred") +
  theme_bw() +
  labs(x = "Subject ID", y = "Weight (kg)")

ggsave_with_metadata(
  filename = file.path(figures_path, "theoph-pk-random.png"),
  plot = random_p,
  meta_type = meta_type$boxplot,
  meta_equations = NULL,
  meta_notes = "Subject-level baseline weight values.",
  meta_abbrevs = c(meta_abbrevs$WTBL),
  height = 4, width = 6
)
