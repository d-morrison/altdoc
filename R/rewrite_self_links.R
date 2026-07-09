# `code-link` resolves the documented package's own functions to an absolute
# URL (`<site-url>/man/<topic>.html` or `<site-url>/vignettes/<path>`, read
# from `altdoc/pkgdown.yml`) rather than a path relative to the linking page.
# That absolute URL only resolves on the exact deploy it was recorded for, so
# it 404s under any other deploy path (most commonly a PR preview served under
# its own subpath). Rewrite each such href into a path relative to the HTML
# file that contains it, which resolves correctly regardless of deploy path.
.rewrite_self_links <- function(docs_dir, path) {
    pkgdown_src <- fs::path_join(c(path, "altdoc", "pkgdown.yml"))
    if (!fs::file_exists(pkgdown_src)) {
        return(invisible())
    }

    urls <- yaml::read_yaml(pkgdown_src)$urls
    if (is.null(urls)) {
        return(invisible())
    }

    # altdoc always renders reference pages to `docs_dir/man` and articles to
    # `docs_dir/vignettes` (see `.import_man()` / `.import_vignettes()`),
    # regardless of what `urls$reference`/`urls$article` in pkgdown.yml say --
    # by convention those also point at `<site-url>/man`/`<site-url>/vignettes`,
    # but even a hand-edited pkgdown.yml with a different URL still resolves to
    # these same on-disk directories, so the relative replacement for whatever
    # URL downlit resolved against is always `<rel-root>/man` /
    # `<rel-root>/vignettes`.
    subdirs <- c(reference = "man", article = "vignettes")
    prefixes <- list()
    for (key in names(subdirs)) {
        url <- urls[[key]]
        if (!is.null(url) && nzchar(url)) {
            prefixes[[length(prefixes) + 1]] <- list(
                url = url,
                subdir = subdirs[[key]]
            )
        }
    }
    if (length(prefixes) == 0) {
        return(invisible())
    }

    html_files <- fs::dir_ls(docs_dir, recurse = TRUE, glob = "*.html")
    for (html_file in html_files) {
        .rewrite_self_links_one(html_file, docs_dir, prefixes)
    }

    invisible()
}
