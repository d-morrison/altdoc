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
# wherever the file is actually served. `.add_pkgdown()` and
# `.substitute_altdoc_variables()` already refuse forge URLs for the same
# reason; `.is_forge_url()` is shared with the former.
.site_url <- function(path = ".") {
    from_pkgdown <- .site_url_from_pkgdown(path)
    if (!is.null(from_pkgdown)) {
        return(from_pkgdown)
    }

    urls <- desc::desc_get_urls(path)
    urls <- urls[!.is_forge_url(urls)]
    if (length(urls) == 0) {
        return(NULL)
    }

    # The first remaining URL is the site by convention; BugReports is a
    # separate DESCRIPTION field and is deliberately not consulted here.
    .strip_trailing_slash(urls[[1]])
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
    reference <- yaml::read_yaml(fn)$urls$reference
    if (is.null(reference) || !nzchar(reference)) {
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
