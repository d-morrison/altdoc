.rewrite_self_links_one <- function(html_file, docs_dir, prefixes) {
    lines <- .readlines(html_file)
    rel_root <- as.character(
        fs::path_rel(docs_dir, start = fs::path_dir(html_file))
    )

    changed <- FALSE
    for (p in prefixes) {
        # strip a trailing slash first so a hand-edited pkgdown.yml URL that
        # already ends in "/" doesn't produce a double-slash pattern that
        # would never match a real href
        base_url <- sub("/$", "", p$url)
        # the trailing "/" makes the directory boundary explicit, so a
        # registered URL ending in "man" can't spuriously match a
        # hypothetical "man-extra/..." href
        pattern <- paste0('href="', base_url, "/")
        hit <- grepl(pattern, lines, fixed = TRUE)
        if (any(hit)) {
            replacement <- paste0('href="', rel_root, "/", p$subdir, "/")
            lines[hit] <- gsub(pattern, replacement, lines[hit], fixed = TRUE)
            changed <- TRUE
        }
    }

    if (changed) {
        writeLines(lines, html_file)
    }
}
