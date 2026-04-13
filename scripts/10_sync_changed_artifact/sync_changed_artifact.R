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
library(ggplot2)
library(dplyr)
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

base_dir <- here::here("scripts", "10_sync_changed_artifact", "output")

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
# Modify one artifact - re-save theoph-pk-exposure.png with a different plot
# ------------------------------------------------------------------------------
message("Modifying theoph-pk-exposure.png to trigger re-insertion...")

theoph_data <- Theoph

p <- ggplot(theoph_data, aes(x = Wt, y = conc)) +
  geom_point() +
  ggtitle("Modified")

ggsave_with_metadata(
  filename = file.path(figures_path, "theoph-pk-exposure.png"),
  plot = p,
  meta_type = get_meta_type(path_to_footnotes_yaml = standard_footnotes)$`linear-regression-plot`,
  meta_equations = NULL,
  meta_notes = "Modified plot for sync test.",
  meta_abbrevs = c(get_meta_abbrevs(path_to_footnotes_yaml = standard_footnotes)$AUC),
  height = 4,
  width = 6
)

# ------------------------------------------------------------------------------
# BUILD 2 - Rebuild from build 1 output (exposure.png changed, others unchanged)
# ------------------------------------------------------------------------------
tic("Build 2 - changed artifact rebuild (should re-insert exposure.png only)")
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

message("Sync changed artifact test complete - exposure.png should be re-inserted, conc.png preserved")

# ------------------------------------------------------------------------------
# Restore original artifacts by re-running the analysis script
# ------------------------------------------------------------------------------
message("Restoring original artifacts...")
source(here::here("scripts", "01_analysis", "analysis.R"))
message("Original artifacts restored.")
