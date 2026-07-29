# The documentation site URL a package declares in `DESCRIPTION`, or NULL when
# it declares none.
#
# `URL:` mixes two kinds of address: the documentation site, and the code
# repository. Only the first is a base for links, so a forge URL is dropped
# rather than used as a fallback -- appending `/man` to a repository root
# yields a path that does not exist. Returning NULL says "this package has no
# site", which lets each caller choose its own degradation: `.site_url()` falls
# back to relative links, and `.add_pkgdown()` omits the `urls:` block so
# `downlit` skips autolinking instead of linking to a 404.
#
# Shared by those two callers so the rule has one home. They previously
# disagreed: `.site_url()` filtered forge URLs out, while `.add_pkgdown()`
# treated the filter as a mere preference and fell back to a forge URL when no
# other candidate existed. See #85.
.description_site_url <- function(path = ".") {
    urls <- desc::desc_get_urls(path)
    urls <- urls[!.is_forge_url(urls)]
    if (length(urls) == 0) {
        return(NULL)
    }

    # The first remaining URL is the site by convention; BugReports is a
    # separate DESCRIPTION field and is deliberately not consulted here.
    return(.strip_trailing_slash(urls[[1]]))
}
