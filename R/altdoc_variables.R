.substitute_altdoc_variables <- function(
    x,
    path = ".",
    tool = "docsify"
) {
    x <- gsub("\\$ALTDOC_VERSION", utils::packageVersion("altdoc"), x)

    files <- c(
        "reference.md",
        "NEWS.md",
        "CHANGELOG.md",
        "CODE_OF_CONDUCT.md",
        "CONTRIBUTING.md",
        "LICENSE.md",
        "LICENCE.md",
        "CITATION.md"
    )
    for (vn in files) {
        fn <- fs::path_join(c(.doc_path(path), vn))
        # `$ALTDOC_` variables are upper case, but the file they point to need
        # not be (e.g. the generated `reference.md`).
        regex <- sprintf(
            "\\$ALTDOC_%s",
            toupper(fs::path_ext_remove(basename(vn)))
        )
        if (
            fs::file_exists(fn) ||
                fs::file_exists(fs::path_join(c(path, "_quarto", vn)))
        ) {
            if (tool == "docute") {
                new <- paste0("/", vn)
            } else {
                new <- vn
            }
            x <- gsub(regex, new, x)
        } else {
            x <- x[!grepl(regex, x)]
        }
    }

    # Logo. Unlike the files above, the name is not fixed -- it is whichever
    # of the four candidates the package actually ships -- so the file to
    # look for comes from `.find_logo()` rather than from the variable name.
    # A package with no logo gets the line dropped, as with a missing file
    # above, so a settings file can carry a logo entry unconditionally.
    logo <- .find_logo(path)
    # `&&` short-circuits, so `basename()` is never reached when there is no
    # logo. The rest checks that the logo was actually imported, so a package
    # that has one but has not rendered yet does not get a reference to a file
    # the site lacks. Both locations are checked for the same reason the file
    # loop above checks both: `quarto_website` stages into `_quarto/` while
    # every other tool writes straight to `docs/`.
    logo_imported <- !is.null(logo) &&
        (fs::file_exists(fs::path_join(c(.doc_path(path), basename(logo)))) ||
            fs::file_exists(
                fs::path_join(c(path, "_quarto", basename(logo)))
            ))
    if (logo_imported) {
        new <- basename(logo)
        if (tool == "docute") {
            new <- paste0("/", new)
        }
        x <- gsub("\\$ALTDOC_LOGO", new, x)
    } else {
        x <- x[!grepl("\\$ALTDOC_LOGO", x)]
    }

    # DESCRIPTION file
    fn <- fs::path_join(c(path, "DESCRIPTION"))
    if (fs::file_exists(fn)) {
        gh_url <- .gh_url(path)
        if (length(gh_url) > 0) {
            x <- gsub("\\$ALTDOC_PACKAGE_URL_GITHUB", gh_url, x)
        } else {
            if (tool == "docsify") {
                x <- gsub("href='\\$ALTDOC_PACKAGE_URL_GITHUB'", "", x)
            } else {
                x <- x[!grepl("\\$ALTDOC_PACKAGE_URL_GITHUB", x)]
            }
        }

        all_urls <- tryCatch(
            desc::desc_get_urls(path),
            error = function(e) NULL
        )
        # `github.com` only, deliberately --- this is not an incomplete
        # `.is_forge_url()` (`R/utils.R`), which `.add_pkgdown()` and
        # `.site_url()` use to keep a repo URL from being treated as a site
        # root. Nothing is appended to this one, so a repo URL here is a
        # working link, not a 404. What it avoids is rendering the same URL
        # twice on one page: `$ALTDOC_PACKAGE_URL_GITHUB` above already carries
        # the repo link, and `.gh_url()` fills that in from
        # `github.com`/`github.io` alone. A GitLab- or Codeberg-hosted package
        # gets nothing from that half, so its URL is the only project link the
        # page has --- widening this filter would drop it and leave none. See
        # #81.
        website_url <- Filter(function(x) !grepl("github.com", x), all_urls)

        if (length(website_url) > 0) {
            x <- gsub("\\$ALTDOC_PACKAGE_URL", website_url[1], x)
        } else {
            if (tool == "docsify") {
                x <- gsub("href='\\$ALTDOC_PACKAGE_URL'", "", x)
            } else {
                x <- x[!grepl("\\$ALTDOC_PACKAGE_URL", x)]
            }
        }

        x <- gsub("\\$ALTDOC_PACKAGE_NAME", desc::desc_get("Package", path), x)
        x <- gsub(
            "\\$ALTDOC_PACKAGE_VERSION",
            desc::desc_get("Version", path),
            x
        )
    } else {
        x <- gsub("\\$ALTDOC_PACKAGE_NAME", "", x)
        x <- gsub("\\$ALTDOC_PACKAGE_VERSION", "", x)
        # There is no URL to substitute, so drop the lines that reference one,
        # as the no-URL branch above does. This has to run before the
        # `$ALTDOC_PACKAGE_URL` substitution below, because that variable's
        # name is a prefix of this one: replacing it first would leave the
        # trailing "_GITHUB" behind on any line mentioning the GitHub URL.
        x <- x[!grepl("\\$ALTDOC_PACKAGE_URL_GITHUB", x)]
        x <- gsub("\\$ALTDOC_PACKAGE_URL", "", x)
    }

    # some commands expand the full path
    x <- gsub(.doc_path(path), "", x, fixed = TRUE)
    x
}
