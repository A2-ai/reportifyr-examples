# ------------------------------------------------------------------------------
# Package installation
# ------------------------------------------------------------------------------
# Now handled by rv via CLI

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
module_dir <- here::here("scripts", "04_add_footnotes")
figures_path  <- here::here("OUTPUTS", "figures")
tables_path <- here::here("OUTPUTS", "tables")
standard_footnotes <- here::here("report", "standard_footnotes.yaml")
config <- here::here("report", "config.yaml")

# ------------------------------------------------------------------------------
# Add footnotes
# ------------------------------------------------------------------------------
add_footnotes(
  docx_in = file.path(module_dir, "template.docx"),
  docx_out = file.path(module_dir, "template-draft.docx"),
  figures_path = figures_path,
  tables_path = tables_path,
  standard_footnotes_yaml = standard_footnotes,
  config_yaml = config,
  include_object_path = FALSE,
  footnotes_fail_on_missing_metadata = TRUE,
  debug = FALSE
)
