# The self-link URL prefix downlit falls back to when it CANNOT discover the
# documented package's site (`<DESCRIPTION URL>/pkgdown.yml` is not fetchable
# at render time -- most commonly a private GitHub Pages deploy, served
# behind auth at an obfuscated domain while the recorded URL 404s):
# `https://rdrr.io/pkg/<pkg>/man/<topic>.html`. rdrr.io only indexes CRAN
# packages, so for a non-CRAN package every such link is dead, while the same
# man pages are rendered locally under `docs_dir/man`.
#
# Only the documented package's own rdrr.io links are rewritten; rdrr.io
# links to base R (`https://rdrr.io/r/...`) and to other packages resolve
# fine on rdrr.io and are left alone. For a package whose site IS
# discoverable, downlit never emits rdrr-form self-links, so this prefix is
# inert there.
.rdrr_fallback_prefixes <- function(path) {
    if (!isTRUE(.dir_is_package(path))) {
        return(list())
    }

    pkg <- .pkg_name(path)
    if (is.null(pkg)) {
        return(list())
    }

    list(list(
        url = paste0("https://rdrr.io/pkg/", pkg, "/man"),
        subdir = "man"
    ))
}
