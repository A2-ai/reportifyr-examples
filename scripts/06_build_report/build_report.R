install.packages("pak")
install.packages("here")

pak::pkg_install("a2-ai/reportifyr")

library(reportifyr)

initialize_report_project(project_dir = here::here())

figures_path  <- here::here("OUTPUTS", "figures")
tables_path <- here::here("OUTPUTS", "tables")
footnotes <- here::here("report", "standard_footnotes.yaml")

build_report(
  docx_in = here::here("report", "shell", "template.docx"), ## Template .docx is placed in reportifyr_examples/report/shell to prevent file shuffling
  docx_out = here::here("report", "draft", "template-draft.docx"),
  figures_path = figures_path,
  tables_path = tables_path,
  standard_footnotes_yaml = footnotes,
  add_footnotes = TRUE,
  include_object_path = FALSE,
  footnotes_fail_on_missing_metadata = TRUE
)
