# Findings about the site URL a package declares.
#
# The URL matters beyond the footer link: `altdoc/pkgdown.yml`'s `urls:` block
# is what `downlit` reads to autolink function calls in vignettes, and
# `.site_url()` uses it to decide whether `llms.txt` gets absolute links. A
# package with no site URL still renders, so nothing fails --- the autolinks
# just quietly do not appear.
.check_altdoc_urls <- function(path = ".") {
    out <- character(0)

    urls <- tryCatch(desc::desc_get_urls(path), error = function(e) {
        character(0)
    })
    if (length(urls) == 0) {
        return(c(
            out,
            "DESCRIPTION declares no `URL:`, so `downlit` cannot autolink function calls in vignettes and `llms.txt` links are site-relative."
        ))
    }

    if (all(.is_forge_url(urls))) {
        out <- c(
            out,
            sprintf(
                "DESCRIPTION's only `URL:` %s a code-hosting repository, not a documentation site, so autolinking has no base URL to work from.",
                if (length(urls) > 1) "entries are" else "entry is"
            )
        )
    }

    fn <- fs::path_join(c(path, "altdoc", "pkgdown.yml"))
    if (!fs::file_exists(fn)) {
        # Written by `.add_pkgdown()` on the first render, so its absence
        # before one is expected rather than a finding.
        return(out)
    }

    .assert_dependency("yaml")
    config <- yaml::read_yaml(fn)
    reference <- if (is.list(config) && is.list(config$urls)) {
        config$urls$reference
    } else {
        NULL
    }
    if (!is.character(reference) || length(reference) != 1) {
        return(out)
    }

    # `altdoc/pkgdown.yml` is hand-editable, so it can disagree with
    # `DESCRIPTION` after either one is changed alone. Neither is wrong on its
    # own --- a site is sometimes served from somewhere other than the first
    # `URL:` --- so this reports the disagreement rather than picking a winner.
    declared <- .strip_trailing_slash(urls)
    if (!any(startsWith(reference, declared))) {
        out <- c(
            out,
            sprintf(
                "`altdoc/pkgdown.yml`'s `urls: reference:` (%s) is under none of DESCRIPTION's `URL:` entries (%s); one of the two is stale.",
                reference,
                paste(declared, collapse = ", ")
            )
        )
    }

    return(out)
}
