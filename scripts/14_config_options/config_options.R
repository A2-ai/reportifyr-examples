# source("scripts/setup_packages.R")
library(reportifyr)
library(here)
library(tictoc)
library(yaml)

initialize_report_project(
  project_dir = here::here(),
  report_dir_name = NULL,
  outputs_dir_name = NULL
)

figures_path <- here::here("OUTPUTS", "figures")
tables_path <- here::here("OUTPUTS", "tables")
standard_footnotes <- here::here("report", "standard_footnotes.yaml")
config <- here::here("report", "config.yaml")

source(here::here("scripts", "config_variants.R"))

message("=== 14: Config options — simple template, all variants ===")
run_config_variants(
  template_path = here::here("report", "shell", "template.docx"),
  base_out_dir = here::here("scripts", "14_config_options", "output"),
  figures_path = figures_path,
  tables_path = tables_path,
  standard_footnotes = standard_footnotes,
  config_path = config,
  finalize = TRUE
)
message("14 complete")
