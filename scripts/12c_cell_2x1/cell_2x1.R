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

message("=== 12c: Cell 2x1 — all config variants ===")
run_config_variants(
  template_path = here::here("report", "shell", "template-cell-1x2.docx"),
  base_out_dir = here::here("scripts", "12c_cell_2x1", "output"),
  figures_path = figures_path,
  tables_path = tables_path,
  standard_footnotes = standard_footnotes,
  config_path = config,
  finalize = TRUE
)
message("12c complete")
