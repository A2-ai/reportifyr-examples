install.packages("pak")
install.packages("here")

pak::pkg_install("a2-ai/reportifyr")

library(reportifyr)

initialize_report_project(project_dir = here::here())

module_dir <- here::here("scripts", "05_remove_tables_figures_footnotes")

remove_tables_figures_footnotes(
  docx_in = file.path(module_dir, "template.docx"),
  docx_out = file.path(module_dir, "template-clean.docx")
)
