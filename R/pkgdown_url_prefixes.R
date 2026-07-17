# The self-link URL prefixes downlit emits when it CAN discover the
# documented package's site: the `reference`/`article` URLs recorded in
# `altdoc/pkgdown.yml`.
#
# altdoc always renders reference pages to `docs_dir/man` and articles to
# `docs_dir/vignettes` (see `.import_man()` / `.import_vignettes()`),
# regardless of what `urls$reference`/`urls$article` in pkgdown.yml say --
# by convention those also point at `<site-url>/man`/`<site-url>/vignettes`,
# but even a hand-edited pkgdown.yml with a different URL still resolves to
# these same on-disk directories, so the relative replacement for whatever
# URL downlit resolved against is always `<rel-root>/man` /
# `<rel-root>/vignettes`.
.pkgdown_url_prefixes <- function(path) {
    pkgdown_src <- fs::path_join(c(path, "altdoc", "pkgdown.yml"))
    if (!fs::file_exists(pkgdown_src)) {
        return(list())
    }

    urls <- yaml::read_yaml(pkgdown_src)$urls
    if (is.null(urls)) {
        return(list())
    }

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
    prefixes
}
