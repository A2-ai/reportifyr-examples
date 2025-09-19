# ------------------------------------------------------------------------------
# Package installation
# ------------------------------------------------------------------------------
install.packages("pak")
install.packages("here")

pak::pkg_install("a2-ai/reportifyr")

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
config <- here::here("report", "config.yaml")

# ------------------------------------------------------------------------------
# Finalize document
# ------------------------------------------------------------------------------
finalize_document(
  docx_in = here::here("report", "draft", "template-draft.docx"),
  docx_out = here::here("report", "final", "template-final.docx"),
  config_yaml = config
)
