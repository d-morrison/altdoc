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
