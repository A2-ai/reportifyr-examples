# ------------------------------------------------------------------------------
# Package installation
# ------------------------------------------------------------------------------
source("scripts/setup_packages.R")

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
module_dir <- here::here("scripts", "05_remove_tables_figures_footnotes")
config <- here::here("report", "config.yaml")

# ------------------------------------------------------------------------------
# Remove tables, figures, and footnotes
# ------------------------------------------------------------------------------
remove_tables_figures_footnotes(
  docx_in = file.path(module_dir, "template.docx"),
  docx_out = file.path(module_dir, "template-clean.docx"),
  config_yaml = config
)
