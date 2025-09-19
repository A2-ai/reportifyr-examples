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
module_dir <- here::here("scripts", "03_add_plots")
figures_path  <- here::here("OUTPUTS", "figures")
config <- here::here("report", "config.yaml")

# ------------------------------------------------------------------------------
# Add plots
# ------------------------------------------------------------------------------
add_plots(
  docx_in = file.path(module_dir, "template.docx"),
  docx_out = file.path(module_dir, "template-figs.docx"),
  figures_path = figures_path,
  config_yaml = config,
  fig_width = NULL,
  fig_height = NULL,
  debug = FALSE
)
