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

test_that(".substitute_altdoc_variables resolves $ALTDOC_CONTRIBUTING", {
    dir <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(dir, "docs")))
    writeLines("Hello", fs::path_join(c(dir, "docs", "CONTRIBUTING.md")))

    out <- .substitute_altdoc_variables(
        c("* [Contributing]($ALTDOC_CONTRIBUTING)"),
        path = dir,
        tool = "docsify"
    )

    expect_identical(out, "* [Contributing](CONTRIBUTING.md)")
})

test_that(".substitute_altdoc_variables drops $ALTDOC_CONTRIBUTING when absent", {
    dir <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(dir, "docs")))

    out <- .substitute_altdoc_variables(
        c("* [Home](/)", "* [Contributing]($ALTDOC_CONTRIBUTING)"),
        path = dir,
        tool = "docsify"
    )

    expect_identical(out, "* [Home](/)")
})

test_that(".substitute_altdoc_variables does not mangle the GitHub URL variable", {
    dir <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(dir, "docs")))

    # `$ALTDOC_PACKAGE_URL` is a prefix of `$ALTDOC_PACKAGE_URL_GITHUB`, so
    # substituting it first would rewrite the GitHub line into a stray
    # "_GITHUB" rather than dropping it. Keep a line that survives, so the
    # residue check runs against real content instead of an empty vector.
    out <- .substitute_altdoc_variables(
        c("* [Home](/)", "* [GitHub]($ALTDOC_PACKAGE_URL_GITHUB)"),
        path = dir,
        tool = "docsify"
    )

    expect_identical(out, "* [Home](/)")
    expect_false(any(grepl("_GITHUB", out)))
})

test_that(".substitute_altdoc_variables resolves $ALTDOC_PACKAGE_AUTHORS, $ALTDOC_PACKAGE_AUTHOR and $ALTDOC_PACKAGE_CONTRIBUTORS from DESCRIPTION", {
    dir <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(dir, "docs")))
    desc_content <- c(
        "Package: testpkg",
        "Version: 1.0.0",
        "Authors@R: c(",
        "    person('Jane', 'Doe', role = c('aut', 'cre'), email = 'jane@example.com'),",
        "    person('John', 'Smith', role = 'aut'),",
        "    person('Alice', 'Bob', role = 'ctb')",
        "  )"
    )
    writeLines(desc_content, fs::path_join(c(dir, "DESCRIPTION")))

    out <- .substitute_altdoc_variables(
        c(
            "Authors: $ALTDOC_PACKAGE_AUTHORS",
            "Author: $ALTDOC_PACKAGE_AUTHOR",
            "Contributors: $ALTDOC_PACKAGE_CONTRIBUTORS"
        ),
        path = dir,
        tool = "docsify"
    )

    expect_identical(
        out,
        c(
            "Authors: Jane Doe, John Smith",
            "Author: Jane Doe, John Smith",
            "Contributors: Alice Bob"
        )
    )
})

test_that(".substitute_altdoc_variables uses Author field as fallback for $ALTDOC_PACKAGE_AUTHORS", {
    dir <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(dir, "docs")))
    desc_content <- c(
        "Package: testpkg",
        "Version: 1.0.0",
        "Author: Jane Doe and John Smith"
    )
    writeLines(desc_content, fs::path_join(c(dir, "DESCRIPTION")))

    out <- .substitute_altdoc_variables(
        c(
            "Authors: $ALTDOC_PACKAGE_AUTHORS",
            "Contributors: $ALTDOC_PACKAGE_CONTRIBUTORS"
        ),
        path = dir,
        tool = "docsify"
    )

    expect_identical(out, "Authors: Jane Doe and John Smith")
})

test_that(".substitute_altdoc_variables drops author and contributor lines when missing", {
    dir <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(dir, "docs")))
    desc_content <- c(
        "Package: testpkg",
        "Version: 1.0.0"
    )
    writeLines(desc_content, fs::path_join(c(dir, "DESCRIPTION")))

    out <- .substitute_altdoc_variables(
        c(
            "Title: $ALTDOC_PACKAGE_NAME",
            "Authors: $ALTDOC_PACKAGE_AUTHORS",
            "Author: $ALTDOC_PACKAGE_AUTHOR",
            "Contributors: $ALTDOC_PACKAGE_CONTRIBUTORS"
        ),
        path = dir,
        tool = "docsify"
    )

    expect_identical(out, "Title: testpkg")
})
