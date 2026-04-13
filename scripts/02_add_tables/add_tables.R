# ------------------------------------------------------------------------------
# Package installation
# ------------------------------------------------------------------------------
# source("scripts/setup_packages.R")

# ------------------------------------------------------------------------------
# Load reportifyr
# ------------------------------------------------------------------------------
library(reportifyr)

# ------------------------------------------------------------------------------
# Initialize report project
# ------------------------------------------------------------------------------
initialize_report_project(
  project_dir = here::here(),
  report_dir_name = NULL,
  outputs_dir_name = NULL
)

# ------------------------------------------------------------------------------
# Set paths
# ------------------------------------------------------------------------------
module_dir <- here::here("scripts", "02_add_tables")
tables_path  <- here::here("OUTPUTS", "tables")
config <- here::here("report", "config.yaml")

# ------------------------------------------------------------------------------
# Add tables
# ------------------------------------------------------------------------------
add_tables(
  docx_in = file.path(module_dir, "template.docx"),
  docx_out = file.path(module_dir, "template-tabs.docx"),
  tables_path = tables_path,
  config_yaml = config,
  debug = FALSE
)
