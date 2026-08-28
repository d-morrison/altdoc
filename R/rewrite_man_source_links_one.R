# Rewrite one man page's repo-action links, from the generated .qmd Quarto
# named to the source file `source_path` names.
#
# Only the trailing `man/<topic>.qmd` is replaced, so whatever the site put in
# front of it -- the repository URL, the branch, and any `repo-subdir:` -- is
# carried through untouched. Both repo actions that name the input file ("View
# source" and "Edit this page") are rewritten; "Report an issue" is built from
# the repository URL alone and never matches.
.rewrite_man_source_links_one <- function(html_file, topic, source_path) {
    lines <- .readlines(html_file)

    pattern <- paste0(
        '(href="[^"]*/)man/',
        .escape_regex(topic),
        '\\.qmd(")'
    )
    hit <- grepl(pattern, lines)
    if (!any(hit)) {
        return(invisible(FALSE))
    }

    lines[hit] <- gsub(
        pattern,
        paste0("\\1", source_path, "\\2"),
        lines[hit]
    )
    writeLines(lines, html_file)

    invisible(TRUE)
}
