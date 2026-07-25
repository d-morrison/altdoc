# Build a data frame describing every topic documented in `<src_dir>/man`, with
# one row per .Rd file. This is the source of truth for the generated reference
# index: the summary shown next to each topic is its \title{}, so it is always
# derived from the .Rd file and can never drift out of sync with it.
#
# Columns:
#   name     topic name (the \name{} tag, which is also the .Rd/.qmd basename)
#   title    \title{}, flattened to a single line of Markdown
#   alias    list column of \alias{} entries
#   keywords list column of \keyword{} entries
#   concepts list column of \concept{} entries (roxygen2's @family)
#   internal TRUE when \keyword{internal} is present
#   is_fun   TRUE when the topic documents something callable
.rd_topics <- function(src_dir = ".") {
    man_dir <- fs::path_join(c(src_dir, "man"))
    if (!fs::dir_exists(man_dir)) {
        return(.rd_topics_empty())
    }

    files <- list.files(man_dir, pattern = "\\.Rd$", full.names = TRUE)
    if (length(files) == 0) {
        return(.rd_topics_empty())
    }

    macros <- tryCatch(
        tools::loadPkgRdMacros(src_dir),
        error = function(e) NULL
    )

    topics <- lapply(files, .rd_topic_one, macros = macros)
    topics <- Filter(Negate(is.null), topics)
    if (length(topics) == 0) {
        return(.rd_topics_empty())
    }

    out <- do.call(
        rbind,
        lapply(topics, function(x) {
            data.frame(
                name = x$name,
                title = x$title,
                internal = x$internal,
                is_fun = x$is_fun,
                stringsAsFactors = FALSE
            )
        })
    )
    out$alias <- lapply(topics, function(x) x$alias)
    out$keywords <- lapply(topics, function(x) x$keywords)
    out$concepts <- lapply(topics, function(x) x$concepts)

    # Sort with the radix method so the index order does not depend on the
    # collation locale, which would make the generated page platform-specific.
    out[order(out$name, method = "radix"), , drop = FALSE]
}
