# Rewrite one man page's repo-action links so they name `source_path` instead
# of the generated .qmd Quarto rendered the page from.
#
# Two things identify a repo action, and both are required: the `/blob/` or
# `/edit/` segment Quarto builds into the URL, and the `toc-action` class it
# puts on the anchor. A page-body link to the same path on the same forge
# satisfies the first and not the second, so it is left alone.
#
# The class is matched as a whitespace-delimited token inside a `class`
# attribute, so an anchor carrying other classes alongside it still matches,
# while a different attribute merely ending in `class` does not, and neither
# does a longer hyphenated class that happens to contain the name.
#
# Everything in front of the trailing `man/<topic>.qmd` is carried through
# untouched -- the repository URL, the branch, and any `repo-subdir:` the site
# sets. "Report an issue" is built from the repository URL alone and never
# matches.
.rewrite_man_source_links_one <- function(html_file, topic, source_path) {
    # Not `.readlines()`: Quarto writes UTF-8, and the default read leaves the
    # strings flagged as native, so `writeLines()` would re-encode the whole
    # document -- every line, not only the ones rewritten -- into whatever the
    # session's locale happens to be. Marking the input UTF-8 and writing with
    # `useBytes` keeps a page with non-ASCII text intact under any locale.
    #
    # That preserves each line's characters, not the file's byte stream: this
    # pair still normalizes line endings and terminates the last line. Both are
    # harmless in HTML, and neither is what the encoding fix is about.
    lines <- readLines(html_file, warn = FALSE, encoding = "UTF-8")

    pattern <- paste0(
        '(href="[^"]*/(blob|edit)/[^"]*/)man/',
        .escape_regex(topic),
        '\\.qmd("[^>]*\\sclass="([^"]*\\s)?toc-action(\\s[^"]*)?")'
    )
    hit <- grepl(pattern, lines)
    if (!any(hit)) {
        return(invisible(FALSE))
    }

    lines[hit] <- gsub(
        pattern,
        paste0("\\1", .url_encode_path(source_path), "\\3"),
        lines[hit]
    )
    writeLines(lines, html_file, useBytes = TRUE)

    invisible(TRUE)
}
