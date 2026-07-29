# Fixtures are built here rather than reusing `tests/testthat/testpkg.*`,
# because none of those declares a non-GitHub forge URL as its only `URL:` --
# which is why #85's fallback went unnoticed in the first place.
.forge_fixture <- function(dir, urls) {
    fs::dir_create(fs::path(dir, "altdoc"))
    writeLines(
        c(
            "Package: forgepkg",
            "Title: Fixture",
            "Version: 0.0.1",
            'Authors@R: person("A", "B", email = "a@b.com", role = c("aut", "cre"))',
            "Description: Fixture.",
            paste0("URL: ", paste(urls, collapse = ", ")),
            "License: MIT + file LICENSE",
            "Encoding: UTF-8"
        ),
        fs::path(dir, "DESCRIPTION")
    )
    return(invisible(dir))
}

test_that(".description_site_url() ignores a repository-only URL", {
    dir <- withr::local_tempdir()
    .forge_fixture(dir, "https://gitlab.com/foo/bar")

    expect_null(.description_site_url(dir))
})

test_that(".description_site_url() prefers the site over a forge URL", {
    dir <- withr::local_tempdir()
    # Forge URL first, so a function returning `urls[[1]]` unconditionally would
    # pick the wrong one -- the ordering is the point of the fixture.
    .forge_fixture(
        dir,
        c("https://codeberg.org/foo/bar", "https://forgepkg.example.org/")
    )

    expect_equal(.description_site_url(dir), "https://forgepkg.example.org")
})

test_that(".add_pkgdown() writes no urls: block for a repository-only URL", {
    dir <- withr::local_tempdir()
    .forge_fixture(dir, "https://gitlab.com/foo/bar")

    expect_message(.add_pkgdown(dir), "No documentation site URL")

    # The whole finding: before #85 this file was written carrying
    # `reference: https://gitlab.com/foo/bar/man`, a path that does not exist.
    expect_false(fs::file_exists(fs::path(dir, "altdoc", "pkgdown.yml")))
})

test_that(".add_pkgdown() still writes urls: when a site URL exists", {
    dir <- withr::local_tempdir()
    .forge_fixture(
        dir,
        c("https://forgepkg.example.org", "https://gitlab.com/foo/bar")
    )

    .add_pkgdown(dir)

    urls <- yaml::read_yaml(fs::path(dir, "altdoc", "pkgdown.yml"))$urls
    expect_equal(urls$reference, "https://forgepkg.example.org/man")
    expect_equal(urls$article, "https://forgepkg.example.org/vignettes")
})

# An `altdoc/pkgdown.yml` written by an earlier render, or by hand. The
# `last_built` value is deliberately stale so a refresh is visible as a change
# rather than as a value that happens to be right.
.existing_pkgdown_yml <- function(dir, urls = NULL) {
    content <- list(
        altdoc = "0.0.0",
        pandoc = "0.0.0",
        pkgdown = "2.1.3",
        last_built = "1970-01-01T00:00:00+0000"
    )
    if (!is.null(urls)) {
        content[["urls"]] <- urls
    }
    yaml::write_yaml(content, fs::path(dir, "altdoc", "pkgdown.yml"))
    return(invisible(dir))
}

test_that(".add_pkgdown() refreshes metadata and keeps a hand-written urls: block", {
    dir <- withr::local_tempdir()
    # The case the first fix regressed: no site URL in DESCRIPTION, but the
    # maintainer has already recorded where the site lives.
    .forge_fixture(dir, "https://gitlab.com/foo/bar")
    .existing_pkgdown_yml(
        dir,
        urls = list(
            reference = "https://forgepkg.example.org/man",
            article = "https://forgepkg.example.org/vignettes"
        )
    )

    .add_pkgdown(dir)

    yml <- yaml::read_yaml(fs::path(dir, "altdoc", "pkgdown.yml"))
    # The refresh is unconditional: it records what produced this render, which
    # does not depend on which `URL:` DESCRIPTION declares.
    expect_equal(yml$altdoc, .altdoc_version())
    expect_false(identical(yml$last_built, "1970-01-01T00:00:00+0000"))
    # The maintainer's block outranks anything derived from DESCRIPTION, so it
    # survives untouched -- and is emphatically not replaced by a forge root.
    expect_equal(yml$urls$reference, "https://forgepkg.example.org/man")
    expect_equal(yml$urls$article, "https://forgepkg.example.org/vignettes")
})

test_that(".add_pkgdown() stays quiet when an existing file already declares urls:", {
    dir <- withr::local_tempdir()
    .forge_fixture(dir, "https://gitlab.com/foo/bar")
    .existing_pkgdown_yml(
        dir,
        urls = list(
            reference = "https://forgepkg.example.org/man",
            article = "https://forgepkg.example.org/vignettes"
        )
    )

    # The advice asks for something the file already has, so printing it here
    # would be telling the maintainer a falsehood about their own file.
    msgs <- capture_messages(.add_pkgdown(dir))
    expect_false(any(grepl("No documentation site URL", msgs)))
})

test_that(".add_pkgdown() still advises when an existing file declares no urls:", {
    dir <- withr::local_tempdir()
    .forge_fixture(dir, "https://gitlab.com/foo/bar")
    # No `urls:` -- the complement of the test above. The pair distinguishes
    # "preserved an existing block" from "skipped the write entirely", which a
    # fixture covering only one side cannot.
    .existing_pkgdown_yml(dir)

    expect_message(.add_pkgdown(dir), "No documentation site URL")

    yml <- yaml::read_yaml(fs::path(dir, "altdoc", "pkgdown.yml"))
    expect_null(yml$urls)
    expect_equal(yml$altdoc, .altdoc_version())
})

test_that(".add_pkgdown() reads the DESCRIPTION at `path`, not the working directory", {
    dir <- withr::local_tempdir()
    .forge_fixture(dir, "https://forgepkg.example.org")

    # A second package, so a `desc_get_urls()` call missing its `path` argument
    # picks this one up instead. Asserting on the *absence* of this URL would
    # pass vacuously, so the assertion names the URL that must be present and
    # this one is only here to be a wrong answer that is available.
    other <- withr::local_tempdir()
    .forge_fixture(other, "https://wrong-package.example.org")

    withr::with_dir(other, .add_pkgdown(dir))

    urls <- yaml::read_yaml(fs::path(dir, "altdoc", "pkgdown.yml"))$urls
    expect_equal(urls$reference, "https://forgepkg.example.org/man")
})
