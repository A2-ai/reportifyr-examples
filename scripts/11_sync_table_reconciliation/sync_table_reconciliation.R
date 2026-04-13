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

base_dir <- here::here("scripts", "11_sync_table_reconciliation", "output")

# ══════════════════════════════════════════════════════════════════════════════
# PATHWAY 1b: Cell text edited, grid shape same → RECONCILE
# ══════════════════════════════════════════════════════════════════════════════

out_1b_build1 <- file.path(base_dir, "1b_build1")
out_1b_build2 <- file.path(base_dir, "1b_build2")
dir.create(out_1b_build1, showWarnings = FALSE, recursive = TRUE)
dir.create(out_1b_build2, showWarnings = FALSE, recursive = TRUE)

# BUILD 1 - Initial build
tic("Pathway 1b: Build 1 - initial build")
build_report(
  docx_in = here::here("report", "shell", "template.docx"),
  docx_out = file.path(out_1b_build1, "draft.docx"),
  figures_path = figures_path,
  tables_path = tables_path,
  standard_footnotes_yaml = standard_footnotes,
  config_yaml = config_sync,
  add_footnotes = TRUE,
  include_object_path = FALSE,
  footnotes_fail_on_missing_metadata = TRUE
)
toc()

# Edit a cell: bold it and change text (reconcile should restore text, keep bold)
message("Pathway 1b: Editing a cell (bold + text change)...")

build1_path <- file.path(out_1b_build1, "draft.docx")
edited_1b_path <- file.path(base_dir, "1b_edited.docx")

edit_script <- tempfile(fileext = ".py")
writeLines(c(
  "import sys",
  "from docx import Document",
  "from docx.oxml.ns import qn",
  "from docx.oxml import OxmlElement",
  paste0("doc = Document('", build1_path, "')"),
  "for table in doc.tables:",
  "    for row in table.rows:",
  "        for cell in row.cells:",
  "            try:",
  "                val = float(cell.text.strip())",
  "                run = cell.paragraphs[0].runs[0]",
  "                run.text = 'EDITED'",
  "                rPr = run._element.find(qn('w:rPr'))",
  "                if rPr is None:",
  "                    rPr = OxmlElement('w:rPr')",
  "                    run._element.insert(0, rPr)",
  "                bold = OxmlElement('w:b')",
  "                rPr.append(bold)",
  paste0("                doc.save('", edited_1b_path, "')"),
  "                sys.exit(0)",
  "            except (ValueError, IndexError):",
  "                pass",
  "print('WARNING: No numeric cell found to edit', file=sys.stderr)",
  "sys.exit(1)"
), edit_script)

paths <- get_venv_uv_paths()
result <- system2(paths$uv, args = c("run", "python", edit_script),
                  stdout = TRUE, stderr = TRUE)
message(paste(result, collapse = "\n"))
if (!file.exists(edited_1b_path)) stop("1b cell edit failed")
message("1b edit complete: ", edited_1b_path)

# BUILD 2 - Reconcile (text restored, bold preserved)
tic("Pathway 1b: Build 2 - reconciliation (should restore text, keep bold)")
build_report(
  docx_in = edited_1b_path,
  docx_out = file.path(out_1b_build2, "draft.docx"),
  figures_path = figures_path,
  tables_path = tables_path,
  standard_footnotes_yaml = standard_footnotes,
  config_yaml = config_sync,
  add_footnotes = TRUE,
  include_object_path = FALSE,
  footnotes_fail_on_missing_metadata = TRUE
)
toc()

message("Pathway 1b complete - check logs for 'Reconciled' messages")

# ══════════════════════════════════════════════════════════════════════════════
# PATHWAY 1c: Grid shape changed (row added) → FULL RESET
# ══════════════════════════════════════════════════════════════════════════════

out_1c_build1 <- file.path(base_dir, "1c_build1")
out_1c_build2 <- file.path(base_dir, "1c_build2")
dir.create(out_1c_build1, showWarnings = FALSE, recursive = TRUE)
dir.create(out_1c_build2, showWarnings = FALSE, recursive = TRUE)

# BUILD 1 - Initial build
tic("Pathway 1c: Build 1 - initial build")
build_report(
  docx_in = here::here("report", "shell", "template.docx"),
  docx_out = file.path(out_1c_build1, "draft.docx"),
  figures_path = figures_path,
  tables_path = tables_path,
  standard_footnotes_yaml = standard_footnotes,
  config_yaml = config_sync,
  add_footnotes = TRUE,
  include_object_path = FALSE,
  footnotes_fail_on_missing_metadata = TRUE
)
toc()

# Add a row to the table (grid shape mismatch → can't reconcile)
message("Pathway 1c: Adding a row to the table (grid mismatch)...")

build1c_path <- file.path(out_1c_build1, "draft.docx")
edited_1c_path <- file.path(base_dir, "1c_edited.docx")

edit_script_1c <- tempfile(fileext = ".py")
writeLines(c(
  "import sys",
  "import copy",
  "from docx import Document",
  "from docx.oxml.ns import qn",
  paste0("doc = Document('", build1c_path, "')"),
  "for table in doc.tables:",
  "    rows = table._tbl.findall(qn('w:tr'))",
  "    if len(rows) > 1:",
  "        # Duplicate the last row to change grid dimensions",
  "        new_row = copy.deepcopy(rows[-1])",
  "        table._tbl.append(new_row)",
  paste0("        doc.save('", edited_1c_path, "')"),
  "        sys.exit(0)",
  "print('WARNING: No table with multiple rows found', file=sys.stderr)",
  "sys.exit(1)"
), edit_script_1c)

result <- system2(paths$uv, args = c("run", "python", edit_script_1c),
                  stdout = TRUE, stderr = TRUE)
message(paste(result, collapse = "\n"))
if (!file.exists(edited_1c_path)) stop("1c row addition failed")
message("1c edit complete: ", edited_1c_path)

# BUILD 2 - Grid mismatch → full reset (table removed and re-inserted fresh)
tic("Pathway 1c: Build 2 - grid mismatch (should fully reset table)")
build_report(
  docx_in = edited_1c_path,
  docx_out = file.path(out_1c_build2, "draft.docx"),
  figures_path = figures_path,
  tables_path = tables_path,
  standard_footnotes_yaml = standard_footnotes,
  config_yaml = config_sync,
  add_footnotes = TRUE,
  include_object_path = FALSE,
  footnotes_fail_on_missing_metadata = TRUE
)
toc()

message("Pathway 1c complete - check logs for 'Grid changed' / full reset messages")
