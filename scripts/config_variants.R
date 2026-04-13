# Shared config variant definitions for test scripts 12-14.
# Each variant is a named list: name, description, and a function that
# modifies a config list and returns it.

library(yaml)

config_variants <- list(
  list(
    name = "default",
    desc = "No config changes",
    modify = function(cfg) cfg
  ),
  list(
    name = "abbrev_delim",
    desc = "abbreviation_delimiter: ;",
    modify = function(cfg) { cfg$abbreviation_delimiter <- ";"; cfg }
  ),
  list(
    name = "hash_footnotes",
    desc = "add_hash_to_footnotes: true",
    modify = function(cfg) { cfg$add_hash_to_footnotes <- TRUE; cfg }
  ),
  list(
    name = "footnote_order",
    desc = "footnote_order with Hash, no Object",
    modify = function(cfg) {
      cfg$footnote_order <- list("Source", "Notes", "Abbreviations", "Hash")
      cfg$add_hash_to_footnotes <- TRUE
      cfg
    }
  ),
  list(
    name = "no_wrap_path",
    desc = "wrap_path_in_[]: false",
    modify = function(cfg) { cfg$`wrap_path_in_[]` <- FALSE; cfg }
  ),
  list(
    name = "object_as_source",
    desc = "use_object_path_as_source: true",
    modify = function(cfg) { cfg$use_object_path_as_source <- TRUE; cfg }
  ),
  list(
    name = "fig_align_left",
    desc = "fig_alignment: left",
    modify = function(cfg) { cfg$fig_alignment <- "left"; cfg }
  ),
  list(
    name = "label_multi_figures",
    desc = "label_multi_figures: true",
    modify = function(cfg) { cfg$label_multi_figures <- TRUE; cfg }
  ),
  list(
    name = "path_overlay",
    desc = "add_path_overlay: true",
    modify = function(cfg) { cfg$add_path_overlay <- TRUE; cfg }
  ),
  list(
    name = "no_embedded_dims",
    desc = "use_embedded_dimensions: false",
    modify = function(cfg) { cfg$use_embedded_dimensions <- FALSE; cfg }
  ),
  list(
    name = "no_footnotes",
    desc = "add_footnotes = FALSE argument",
    modify = function(cfg) cfg  # config unchanged, argument changes
  ),
  list(
    name = "no_alt_text",
    desc = "add_alt_text: false",
    modify = function(cfg) { cfg$add_alt_text <- FALSE; cfg }
  ),
  list(
    name = "no_combine_dupes",
    desc = "combine_duplicate_footnotes: false",
    modify = function(cfg) { cfg$combine_duplicate_footnotes <- FALSE; cfg }
  ),
  list(
    name = "no_keep_caption",
    desc = "keep_caption_next: false",
    modify = function(cfg) { cfg$keep_caption_next <- FALSE; cfg }
  )
)

#' Run build_report for each config variant
#'
#' @param template_path Path to input docx template
#' @param base_out_dir Base output directory (variants create subdirs)
#' @param figures_path Path to figures directory
#' @param tables_path Path to tables directory
#' @param standard_footnotes Path to standard_footnotes.yaml
#' @param config_path Path to base config.yaml
#' @param finalize Logical, whether to also run finalize_document
run_config_variants <- function(template_path, base_out_dir, figures_path,
                                tables_path, standard_footnotes, config_path,
                                finalize = FALSE) {
  base_cfg <- yaml::read_yaml(config_path)

  for (variant in config_variants) {
    out_dir <- file.path(base_out_dir, variant$name)
    dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

    cfg <- variant$modify(base_cfg)
    cfg_file <- tempfile(fileext = ".yaml")
    yaml::write_yaml(cfg, cfg_file)

    add_fn <- variant$name != "no_footnotes"

    message(sprintf("  [%s] %s", variant$name, variant$desc))
    tictoc::tic(variant$name)
    build_report(
      docx_in = template_path,
      docx_out = file.path(out_dir, "draft.docx"),
      figures_path = figures_path,
      tables_path = tables_path,
      standard_footnotes_yaml = standard_footnotes,
      config_yaml = cfg_file,
      add_footnotes = add_fn,
      include_object_path = FALSE,
      footnotes_fail_on_missing_metadata = TRUE
    )
    tictoc::toc()

    if (finalize) {
      finalize_document(
        docx_in = file.path(out_dir, "draft.docx"),
        docx_out = file.path(out_dir, "final.docx"),
        config_yaml = cfg_file
      )
    }
  }
}

#' Run sync (build twice) for each config variant
run_sync_variants <- function(template_path, base_out_dir, figures_path,
                              tables_path, standard_footnotes, config_path) {
  base_cfg <- yaml::read_yaml(config_path)

  for (variant in config_variants) {
    # Sync always needs skip_unchanged = TRUE
    cfg <- variant$modify(base_cfg)
    cfg$skip_unchanged <- TRUE
    cfg_file <- tempfile(fileext = ".yaml")
    yaml::write_yaml(cfg, cfg_file)

    add_fn <- variant$name != "no_footnotes"

    out_b1 <- file.path(base_out_dir, variant$name, "build1")
    out_b2 <- file.path(base_out_dir, variant$name, "build2")
    dir.create(out_b1, showWarnings = FALSE, recursive = TRUE)
    dir.create(out_b2, showWarnings = FALSE, recursive = TRUE)

    message(sprintf("  [%s] build1", variant$name))
    tictoc::tic(paste0(variant$name, " build1"))
    build_report(
      docx_in = template_path,
      docx_out = file.path(out_b1, "draft.docx"),
      figures_path = figures_path,
      tables_path = tables_path,
      standard_footnotes_yaml = standard_footnotes,
      config_yaml = cfg_file,
      add_footnotes = add_fn,
      include_object_path = FALSE,
      footnotes_fail_on_missing_metadata = TRUE
    )
    tictoc::toc()

    message(sprintf("  [%s] build2 (sync)", variant$name))
    tictoc::tic(paste0(variant$name, " build2"))
    build_report(
      docx_in = file.path(out_b1, "draft.docx"),
      docx_out = file.path(out_b2, "draft.docx"),
      figures_path = figures_path,
      tables_path = tables_path,
      standard_footnotes_yaml = standard_footnotes,
      config_yaml = cfg_file,
      add_footnotes = add_fn,
      include_object_path = FALSE,
      footnotes_fail_on_missing_metadata = TRUE
    )
    tictoc::toc()
  }
}
