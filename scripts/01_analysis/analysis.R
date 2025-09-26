# ------------------------------------------------------------------------------
# Package installation
# ------------------------------------------------------------------------------
install.packages("pak")
install.packages("here")
install.packages("ggplot2")
install.packages("dplyr")

pak::pkg_install("a2-ai/reportifyr")

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
