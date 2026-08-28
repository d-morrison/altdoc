# Rewrite one man page's repo-action links so they name `source_path` instead
# of the generated .qmd Quarto rendered the page from.
#
# The match is anchored on the `/blob/` or `/edit/` segment Quarto writes into
# a repo action's URL, so an ordinary link in the page's own body that happens
# to end in the same path is left alone. Everything in front of that trailing
# `man/<topic>.qmd` is carried through untouched -- the repository URL, the
# branch, and any `repo-subdir:` the site sets. "Report an issue" is built from
# the repository URL alone and never matches.
.rewrite_man_source_links_one <- function(html_file, topic, source_path) {
    lines <- .readlines(html_file)

    pattern <- paste0(
        '(href="[^"]*/(blob|edit)/[^"]*/)man/',
        .escape_regex(topic),
        '\\.qmd(")'
    )
    hit <- grepl(pattern, lines)
    if (!any(hit)) {
        return(invisible(FALSE))
    }

    # `source_path` is data, and a backslash in it would read as a
    # backreference in the replacement. roxygen2's `@backref` takes any path,
    # so the escape is what keeps such a filename literal.
    replacement <- gsub("\\", "\\\\", source_path, fixed = TRUE)

    lines[hit] <- gsub(
        pattern,
        paste0("\\1", replacement, "\\3"),
        lines[hit]
    )
    writeLines(lines, html_file)

    invisible(TRUE)
}
