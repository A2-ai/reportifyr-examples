# ------------------------------------------------------------------------------
# Package installation
# ------------------------------------------------------------------------------
# source("scripts/setup_packages.R")

# ------------------------------------------------------------------------------
# Load libraries
# ------------------------------------------------------------------------------
library(reportifyr)
library(here)
library(tictoc)
library(yaml)

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
figures_path <- here::here("OUTPUTS", "figures")
tables_path <- here::here("OUTPUTS", "tables")
standard_footnotes <- here::here("report", "standard_footnotes.yaml")
config <- here::here("report", "config.yaml")

# Enable skip_unchanged
config_data <- yaml::read_yaml(config)
config_data$skip_unchanged <- TRUE
config_sync <- tempfile(fileext = ".yaml")
yaml::write_yaml(config_data, config_sync)

base_dir <- here::here("scripts", "09_sync_unchanged", "output")

out_build1 <- file.path(base_dir, "build1")
out_build2 <- file.path(base_dir, "build2")
dir.create(out_build1, showWarnings = FALSE, recursive = TRUE)
dir.create(out_build2, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------------------------
# BUILD 1 - Initial build from shell template
# ------------------------------------------------------------------------------
tic("Build 1 - initial build")
build_report(
  docx_in = here::here("report", "shell", "template.docx"),
  docx_out = file.path(out_build1, "draft.docx"),
  figures_path = figures_path,
  tables_path = tables_path,
  standard_footnotes_yaml = standard_footnotes,
  config_yaml = config_sync,
  add_footnotes = TRUE,
  include_object_path = FALSE,
  footnotes_fail_on_missing_metadata = TRUE
)
toc()

# ------------------------------------------------------------------------------
# BUILD 2 - Rebuild from build 1 output (no artifacts changed)
# ------------------------------------------------------------------------------
tic("Build 2 - unchanged rebuild (should skip all artifacts)")
build_report(
  docx_in = file.path(out_build1, "draft.docx"),
  docx_out = file.path(out_build2, "draft.docx"),
  figures_path = figures_path,
  tables_path = tables_path,
  standard_footnotes_yaml = standard_footnotes,
  config_yaml = config_sync,
  add_footnotes = TRUE,
  include_object_path = FALSE,
  footnotes_fail_on_missing_metadata = TRUE
)
toc()

message("Sync unchanged test complete - check logs for skip messages")
