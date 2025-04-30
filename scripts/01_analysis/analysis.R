install.packages("pak")
install.packages("here")
install.packages("ggplot2")
install.packages("dplyr")

pak::pkg_install("a2-ai/reportifyr")

library(reportifyr)
library(ggplot2)
library(dplyr)

initialize_report_project(project_dir = here::here())

meta_type <- get_meta_type(path_to_footnotes_yaml = here::here("report", "standard_footnotes.yaml"))
meta_abbrevs <- get_meta_abbrevs(path_to_footnotes_yaml = here::here("report", "standard_footnotes.yaml"))

figures_path <- here::here("OUTPUTS", "figures")
tables_path  <- here::here("OUTPUTS", "tables")

source(here::here("scripts", "01_analysis", "function.R"))

data <- Theoph

pk_params <- data %>%
  mutate(Subject = as.numeric(Subject)) %>%
  group_by(Subject) %>%
  summarise(
    cmax = max(conc, na.rm = TRUE),
    tmax = Time[which.max(conc)],
    auc = calc_auc_linear_log(Time, conc),
    wt = Wt %>% unique()
  )

knitr::kable(pk_params)

outfile_name <- "theoph-pk-parameters.csv"

write_csv_with_metadata(object = pk_params,
                        file = file.path(tables_path, outfile_name),
                        meta_type = meta_type$`parameter-summary`,
                        meta_notes = "AUC was calculated using linear trapezoidal integration for ascending and non-loggable segments and log-linear trapezoidal integration for descending segments.",
                        meta_equations = NULL,
                        meta_abbrevs = c(meta_abbrevs$AUC, meta_abbrevs$CMAX, meta_abbrevs$TMAX, meta_abbrevs$WT),
                        table1_format = FALSE,
                        row.names = FALSE)

lr <- pk_params %>%
  ggplot(aes(x = wt, y = auc)) +
  geom_point() +
  geom_smooth(method = "lm", formula = y ~ x, se = TRUE, color = "blue") +
  theme_bw() +
  labs(x = "Subject weight (kg)", y = "AUC (hr*mg/L)")

lr

plot_file_name <- "theoph-pk-exposure.png"

ggsave_with_metadata(filename = file.path(figures_path, plot_file_name),
                     plot = lr,
                     meta_type = meta_type$`linear-regression-plot`,
                     meta_equations = "y = b0 + b1 * x + e",
                     meta_notes = "AUC was calculated using linear trapezoidal integration for ascending and non-loggable segments and log-linear trapezoidal integration for descending segments.",
                     meta_abbrevs = c(meta_abbrevs$AUC),
                     height = 4,
                     width = 6)
