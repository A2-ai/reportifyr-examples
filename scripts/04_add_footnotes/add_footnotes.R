install.packages("pak")
install.packages("here")

pak::pkg_install("a2-ai/reportifyr")

library(reportifyr)

initialize_report_project(project_dir = here::here())

module_dir <- here::here("scripts", "04_add_footnotes")
figures_path  <- here::here("OUTPUTS", "figures")
tables_path <- here::here("OUTPUTS", "tables")
footnotes <- here::here("report", "standard_footnotes.yaml")

add_footnotes(
  docx_in = file.path(module_dir, "template.docx"),
  docx_out = file.path(module_dir, "template-draft.docx"),
  figures_path = figures_path,
  tables_path = tables_path,
  footnotes = footnotes,
  include_object_path = FALSE,
  footnotes_fail_on_missing_metadata = TRUE
)
