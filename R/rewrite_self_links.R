# `code-link` resolves the documented package's own functions to an absolute
# URL that never survives every deploy:
#
# * When downlit can discover the package's site (by fetching
#   `<DESCRIPTION URL>/pkgdown.yml` at render time), it emits the absolute
#   production-site URL recorded in `altdoc/pkgdown.yml`, which only resolves
#   on the exact deploy it was recorded for and 404s under any other deploy
#   path (most commonly a PR preview served under its own subpath). See
#   `.pkgdown_url_prefixes()`.
# * When it cannot (most commonly a private GitHub Pages site, whose
#   pkgdown.yml is not fetchable without auth), it falls back to
#   `https://rdrr.io/pkg/<pkg>/man/<topic>.html`, which 404s for any package
#   not on CRAN since rdrr.io only indexes CRAN. See
#   `.rdrr_fallback_prefixes()`.
#
# Either way the target page is rendered locally under `docs_dir`, so rewrite
# each such href into a path relative to the HTML file that contains it, which
# resolves correctly regardless of deploy path.
.rewrite_self_links <- function(docs_dir, path) {
    prefixes <- c(
        .pkgdown_url_prefixes(path),
        .rdrr_fallback_prefixes(path)
    )
    if (length(prefixes) == 0) {
        return(invisible())
    }

    html_files <- fs::dir_ls(docs_dir, recurse = TRUE, glob = "*.html")
    for (html_file in html_files) {
        .rewrite_self_links_one(html_file, docs_dir, prefixes)
    }

    invisible()
}
