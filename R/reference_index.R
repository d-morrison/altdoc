# Build the Markdown of the reference index page.
#
# Every summary is the topic's \title{}, read from its .Rd file, so the index is
# regenerated from the same source as the man pages themselves on every
# `render_docs()` call and can never drift out of sync with them.
#
# `ext` is the file extension of the rendered man pages, which differs by
# documentation generator: quarto_website links to .qmd, the others to .md.
# `title` is the page's top-level heading; `.reference_title()` supplies it,
# including the default when the settings file does not name one.
.reference_index <- function(
    sections,
    topics,
    ext = "md",
    title = "Package index"
) {
    env <- .topics_env(topics)
    listed <- integer(0)
    out <- c(paste("#", title), "")

    for (section in sections) {
        selected <- .select_topics(section$contents, topics, env = env)
        listed <- union(listed, selected)

        if (!is.null(section$title)) {
            out <- c(out, paste("##", section$title), "")
        }
        if (!is.null(section$subtitle)) {
            out <- c(out, paste("###", section$subtitle), "")
        }
        if (!is.null(section$desc)) {
            out <- c(out, section$desc, "")
        }
        if (length(selected) > 0) {
            out <- c(
                out,
                .reference_rows(topics[selected, , drop = FALSE], ext),
                ""
            )
        }
    }

    missing <- setdiff(which(!topics$internal), listed)
    if (length(missing) > 0) {
        names_missing <- topics$name[missing]
        cli::cli_alert_warning(
            "{length(missing)} topic{?s} missing from {.file altdoc/reference.yml}: {.val {names_missing}}."
        )
        cli::cli_alert_info(
            "{cli::qty(length(missing))}Add {?it/them} to a section, or use {.code @keywords internal} to drop {?it/them} from the index."
        )
        out <- c(
            out,
            "## Other",
            "",
            .reference_rows(topics[missing, , drop = FALSE], ext),
            ""
        )
    }

    # A trailing blank line is enough; drop any others left by an empty section.
    while (length(out) > 0 && !nzchar(out[length(out)])) {
        out <- out[-length(out)]
    }
    c(out, "")
}
