# ------------------------------------------------------------------------------
# XYZ-101: report shell
#
# Each artifact is: caption, magic string, empty paragraph.
# ------------------------------------------------------------------------------
library(officer)

shell_docx <- here::here("report", "shell", "xyz101-pk-report.docx")

artifacts <- list(
  c("Table 1: Summary of Subject Demographics by Dose Cohort", "xyz101-demographics.rds"),
  c("Figure 1: Individual Concentration-Time Profiles by Dose Cohort", "xyz101-conc-individual.png"),
  c("Figure 2: Mean (SD) Concentration-Time Profiles by Dose Cohort", "xyz101-conc-mean.png"),
  c("Table 2: Mean Concentrations by Nominal Time and Dose Cohort", "xyz101-mean-conc.rds"),
  c("Table 3: Summary of Noncompartmental PK Parameters by Dose Cohort", "xyz101-nca-summary.rds"),
  c("Figure 3: Dose-Normalized Cmax and AUC0-inf by Dose Cohort", "xyz101-dose-normalised.png"),
  c("Table 4: Power-Model Assessment of Dose Proportionality", "xyz101-power-model.rds"),
  c("Figure 4: Cmax and AUC0-inf Versus Dose With Power-Model Fit", "xyz101-dose-proportionality.png"),
  c("Figure 5: CL/F Versus Body Weight and Creatinine Clearance", "xyz101-clf-covariates.png"),
  c("Table 5: Individual Noncompartmental PK Parameters", "xyz101-nca-individual.csv")
)

doc <- read_docx() |>
  docx_set_paragraph_style(
    style_id = "Caption",
    style_name = "Caption",
    fp_t = fp_text_lite(bold = TRUE)
  )

for (a in artifacts) {
  doc <- doc |>
    body_add_par(a[1], style = "Caption") |>
    body_add_par(paste0("{rpfy}:", a[2]), style = "Normal") |>
    body_add_par("", style = "Normal")
}

print(doc, target = shell_docx)
