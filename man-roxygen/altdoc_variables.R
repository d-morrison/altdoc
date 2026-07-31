#' @section Altdoc variables:
#'
#' The settings files in the `altdoc/` directory can include `$ALTDOC` variables which are replaced automatically by `altdoc` when calling `render_docs()`:
#'
#' * `$ALTDOC_PACKAGE_NAME`: Name of the package from `DESCRIPTION`.
#' * `$ALTDOC_PACKAGE_VERSION`: Version number of the package from `DESCRIPTION`
#' * `$ALTDOC_PACKAGE_URL`: First URL listed in the DESCRIPTION file of the package.
#' * `$ALTDOC_PACKAGE_URL_GITHUB`: First URL that contains "github.com" from the URLs listed in the DESCRIPTION file of the package. If no such URL is found, lines containing this variable are removed from the settings file.
#' * `$ALTDOC_LOGO`: File name of the package logo, which `render_docs()` copies into the website root. The first of `logo.svg`, `man/figures/logo.svg`, `logo.png`, or `man/figures/logo.png` to exist is used. If the package has no logo, lines containing this variable are removed from the settings file. Of the settings files created by `setup_docs()`, only `quarto_website.yml` refers to this variable; add it yourself to use a logo with another documentation generator, or to a settings file created before this variable existed.
#' * `$ALTDOC_MAN_BLOCK`: Nested list of links to the individual help pages for each exported function of the package. The format of this block depends on the documentation generator.
#' * `$ALTDOC_REFERENCE`: Link to the generated reference index, a page listing every documented topic with a one-line summary. See the "Reference index" section below.
#' * `$ALTDOC_VIGNETTE_BLOCK`: Nested list of links to the vignettes. The format of this block depends on the documentation generator.
#' * `$ALTDOC_SIDEBAR_FOLD`: File name of a snippet adding a navbar button that folds the whole sidebar away, giving the content the width the sidebar held. Quarto's own `collapse-level` folds sections *within* the sidebar and has no control for the sidebar itself. This snippet is shipped by altdoc rather than created in `altdoc/`, so a site picks up changes to it by upgrading the package. Point `include-in-header` at it under `format: html:` in `altdoc/quarto_website.yml`:
#'
#' ```yaml
#' format:
#'   html:
#'     include-in-header: $ALTDOC_SIDEBAR_FOLD
#' ```
#'
#'   The reader's choice is remembered across pages, and the sidebar starts open unless `sidebar_fold: collapsed` is set in `altdoc/reference.yml`. Below Quarto's own 992px breakpoint the sidebar is already a drawer laid over the content, so no button is shown. This variable resolves only for the `quarto_website` generator; lines containing it are removed from the settings file of any other.
#' * `$ALTDOC_VERSION`: Version number of the altdoc package.
#'
#' Also note that you can store images and static files in the `altdoc/` directory. All the files in this folder are copied to `docs/` and made available in the root of the website, so you can link to them easily.
#'
