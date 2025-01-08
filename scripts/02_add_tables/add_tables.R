install.packages("pak")
install.packages("here")

pak::pkg_install("a2-ai/reportifyr")

library(reportifyr)

initialize_report_project(project_dir = here::here())

module_dir <- here::here("scripts", "02_add_tables")
tables_path  <- here::here("OUTPUTS", "tables")

add_tables(
    docx_in = file.path(module_dir, "template.docx"),
    docx_out = file.path(module_dir, "template-tabs.docx"),
    tables_path = tables_path
  )
