test_that(".substitute_altdoc_variables blanks the package variables with no DESCRIPTION", {
    dir <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(dir, "docs")))

    out <- .substitute_altdoc_variables(
        c("title: $ALTDOC_PACKAGE_NAME", "version: $ALTDOC_PACKAGE_VERSION"),
        path = dir,
        tool = "docsify"
    )

    expect_identical(out, c("title: ", "version: "))
})

test_that(".substitute_altdoc_variables drops URL lines with no DESCRIPTION", {
    dir <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(dir, "docs")))

    out <- .substitute_altdoc_variables(
        c(
            "* [Home](/)",
            "* [GitHub]($ALTDOC_PACKAGE_URL_GITHUB)",
            "* [Website]($ALTDOC_PACKAGE_URL)"
        ),
        path = dir,
        tool = "docsify"
    )

    # The GitHub line goes entirely; the website line keeps its text because
    # the variable is substituted with an empty string.
    expect_identical(out, c("* [Home](/)", "* [Website]()"))
})

test_that(".substitute_altdoc_variables does not mangle the GitHub URL variable", {
    dir <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(dir, "docs")))

    # `$ALTDOC_PACKAGE_URL` is a prefix of `$ALTDOC_PACKAGE_URL_GITHUB`, so
    # substituting it first would leave a stray "_GITHUB" behind.
    out <- .substitute_altdoc_variables(
        "* [GitHub]($ALTDOC_PACKAGE_URL_GITHUB)",
        path = dir,
        tool = "docsify"
    )

    expect_identical(out, character(0))
    expect_false(any(grepl("_GITHUB", out)))
})
