install.packages("pak")
install.packages("here")

pak::pkg_install("a2-ai/reportifyr")

library(reportifyr)

initialize_report_project(project_dir = here::here())

finalize_document(
  docx_in = here::here("report", "draft", "template-draft.docx"), ## Using prepared draft from 06_build_report
  docx_out = here::here("report", "final", "template-final.docx")
)
