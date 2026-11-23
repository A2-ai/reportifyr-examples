# ------------------------------------------------------------------------------
# XYZ-101: build the report
# ------------------------------------------------------------------------------
library(reportifyr)

# ------------------------------------------------------------------------------
# Set paths
# ------------------------------------------------------------------------------
figures_path <- here::here("OUTPUTS", "figures")
tables_path <- here::here("OUTPUTS", "tables")
standard_footnotes <- here::here("report", "standard_footnotes.yaml")
config <- here::here("report", "config.yaml")

# ------------------------------------------------------------------------------
# Build report
# ------------------------------------------------------------------------------
build_report(
  docx_in = here::here("report", "shell", "xyz101-pk-report.docx"),
  docx_out = here::here("report", "draft", "xyz101-pk-report-draft.docx"),
  figures_path = figures_path,
  tables_path = tables_path,
  standard_footnotes_yaml = standard_footnotes,
  config_yaml = config,
  add_footnotes = TRUE,
  include_object_path = FALSE,
  footnotes_fail_on_missing_metadata = TRUE
)
