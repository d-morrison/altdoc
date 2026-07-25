# Generate the reference index page in `<tar_dir>/reference.md`.
#
# The page lists every documented topic with a one-line summary read from its
# .Rd \title{}, grouped into the sections declared in `altdoc/reference.yml`.
# It is rebuilt on every `render_docs()` call, so the summaries always match the
# .Rd files they came from.
.import_reference <- function(src_dir, tar_dir, tool = "docsify") {
    topics <- .rd_topics(src_dir)
    if (nrow(topics) == 0) {
        return(invisible())
    }

    # Read once here so the heading and the grouping cannot disagree about what
    # `altdoc/reference.yml` says.
    settings <- .reference_settings(src_dir)
    sections <- .reference_sections(settings, topics)
    if (length(sections) == 0) {
        return(invisible())
    }

    # `.render_one_man()` keeps the .qmd only for quarto_website; every other
    # generator renders the man pages down to .md.
    ext <- if (identical(tool, "quarto_website")) "qmd" else "md"

    content <- .reference_index(
        sections,
        topics,
        ext = ext,
        title = .reference_title(settings)
    )
    writeLines(content, fs::path_join(c(tar_dir, "reference.md")))

    cli::cli_alert_success(
        "Reference index written with {nrow(topics)} topic{?s}."
    )

    invisible()
}
