install.packages("pak")
install.packages("here")

pak::pkg_install("a2-ai/reportifyr")

library(reportifyr)

initialize_report_project(project_dir = here::here())

module_dir <- here::here("scripts", "03_add_plots")
figures_path  <- here::here("OUTPUTS", "figures")

add_plots(
  docx_in = file.path(module_dir, "template.docx"),
  docx_out = file.path(module_dir, "template-figs.docx"),
  figures_path = figures_path
)
