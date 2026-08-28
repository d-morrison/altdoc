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
# sets. That prefix must be the site's own `repo-url`, which is what separates
# these from "Report an issue" -- it carries the same class, and `issue-url` is
# arbitrary, so it can name any path at all. A line whose href starts with the
# site's `issue-url` is skipped outright, for an `issue-url` that sits under
# the repository and so satisfies the prefix too.
.rewrite_man_source_links_one <- function(
    html_file,
    topic,
    source_path,
    repo_url,
    issue_url = NULL
) {
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

    # `/(blob|edit)/` follows `repo-url` immediately -- `repo-subdir:` lands
    # after the branch, inside the repository path -- so anchoring on that
    # boundary is exact, and it stops `.../pkg` from matching a page-level
    # override of `.../pkg-docs`.
    pattern <- paste0(
        '(href="',
        .escape_regex(repo_url),
        '/(blob|edit)/[^"?#]*/)man/',
        .escape_regex(topic),
        '\\.qmd("[^>]*\\sclass="([^"]*\\s)?toc-action(\\s[^"]*)?")'
    )

    # Quarto serializes all three repo actions onto one line, so the
    # `issue-url` cannot be excluded by dropping the line it appears on --
    # that would take the source and edit links with it, on every page of any
    # site that sets one. Mask it for the substitution and put it back after.
    #
    # The whole href is masked, closing quote included: Quarto emits the issue
    # action as exactly the configured URL, so a prefix match would hide every
    # action on a site whose `issue-url` and `repo-url` are the same value.
    #
    # An `issue-url` set to the source action's own URL is indistinguishable
    # from it and stays masked, which loses that one link rather than
    # corrupting the issue action.
    original <- lines
    sentinel <- "\u0001altdoc-issue-url\u0001"
    if (!is.null(issue_url)) {
        lines <- gsub(
            paste0('href="', issue_url, '"'),
            paste0('href="', sentinel, '"'),
            lines,
            fixed = TRUE
        )
    }

    hit <- grepl(pattern, lines)
    if (any(hit)) {
        lines[hit] <- gsub(
            pattern,
            paste0("\\1", .url_encode_path(source_path), "\\3"),
            lines[hit]
        )
    }

    if (!is.null(issue_url)) {
        lines <- gsub(
            paste0('href="', sentinel, '"'),
            paste0('href="', issue_url, '"'),
            lines,
            fixed = TRUE
        )
    }

    if (identical(lines, original)) {
        return(invisible(FALSE))
    }

    writeLines(lines, html_file, useBytes = TRUE)

    invisible(TRUE)
}
