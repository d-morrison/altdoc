# The base URL the rendered site is served from, or NULL when the package does
# not declare one.
#
# `llms.txt` conventionally uses absolute URLs, because a consumer fetches the
# index and then fetches the pages it lists, often without keeping track of
# where the index itself came from. So the generated file needs a site root,
# and this is where it comes from.
#
# The source is `altdoc/pkgdown.yml`'s `urls$reference`, with `DESCRIPTION`'s
# `URL:` as the fallback. That order looks backwards -- `DESCRIPTION` is the
# more canonical field -- but `altdoc/pkgdown.yml` is the file a maintainer
# edits when the site is served from somewhere other than the first `URL:`
# entry, and `rewrite_self_links.R` already treats it as the record of where
# the site lives. Reading it first keeps this function agreeing with that one.
#
# A forge URL is never a site. A package whose only `URL:` is its GitHub
# repository is common, and using it as the base yields links like
# `https://github.com/user/pkg/man/foo.md`, which do not exist. Returning NULL
# instead falls back to relative links, which at least resolve against
# wherever the file is actually served. That rule now lives in
# `.description_site_url()`, which this function and `.add_pkgdown()` share, so
# the two cannot disagree about which `URL:` is a site.
#
# They did disagree until #85: `.add_pkgdown()` treated the filter as a mere
# *preference*, falling back to a forge URL when no other candidate existed and
# appending `/man` and `/vignettes` to it, so a package whose only `URL:` was
# its GitLab repo got `reference: https://gitlab.com/o/r/man` written into
# `altdoc/pkgdown.yml`. The `.is_forge_url(root)` guard in
# `.site_url_from_pkgdown()` below was what caught that value on the way back
# *in*. It is kept: `altdoc/pkgdown.yml` is hand-editable and can predate the
# fix, so the guard still has work to do on a file this package did not write.
#
# `.substitute_altdoc_variables()` is not a third instance of the same rule,
# though it looks like one. It drops only `github.com` from
# `$ALTDOC_PACKAGE_URL`, and not to avoid a broken link --- it appends no path,
# so a repo URL there resolves fine. It is avoiding a duplicate: the templates
# render `$ALTDOC_PACKAGE_URL_GITHUB` as the repo link on the same page, and
# `.gh_url()` populates that one from `github.com`/`github.io` only. Widening
# its filter to `.is_forge_url()` would therefore leave a GitLab- or
# Codeberg-hosted package with no link to its project at all, since neither
# half would fire. See #81.
.site_url <- function(path = ".") {
    from_pkgdown <- .site_url_from_pkgdown(path)
    if (!is.null(from_pkgdown)) {
        return(from_pkgdown)
    }

    return(.description_site_url(path))
}

# The site root implied by `altdoc/pkgdown.yml`'s `urls$reference`, which by
# convention points at the reference subdirectory (`<site>/man`), so the
# trailing path segment is dropped to recover the root.
.site_url_from_pkgdown <- function(path = ".") {
    fn <- fs::path_join(c(path, "altdoc", "pkgdown.yml"))
    if (!fs::file_exists(fn)) {
        return(NULL)
    }

    .assert_dependency("yaml")

    # This file is the one a maintainer hand-edits, so it can hold shapes the
    # convention does not anticipate: `urls` written as a bare scalar, or
    # `reference` as a list of URLs. Indexing straight through would abort the
    # whole `render_docs()` call on `$ operator is invalid for atomic vectors`
    # or a length-2 condition, turning a documentation nicety into a hard
    # failure. Anything that is not a single non-empty string falls through to
    # the `DESCRIPTION` fallback this function already documents.
    config <- yaml::read_yaml(fn)
    urls <- if (is.list(config)) config$urls else NULL
    reference <- if (is.list(urls)) urls$reference else NULL

    if (
        !is.character(reference) ||
            length(reference) != 1 ||
            is.na(reference) ||
            !nzchar(reference)
    ) {
        return(NULL)
    }

    reference <- .strip_trailing_slash(reference)
    root <- sub("/[^/]+$", "", reference)

    # A `urls$reference` with no path segment to drop (just a host) leaves
    # `root` equal to the scheme, which is not a usable base.
    if (!grepl("^https?://[^/]+", root)) {
        return(NULL)
    }
    if (.is_forge_url(root)) {
        return(NULL)
    }
    root
}

.strip_trailing_slash <- function(x) {
    sub("/+$", "", x)
}
