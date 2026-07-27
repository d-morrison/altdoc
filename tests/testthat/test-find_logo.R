local_logo_package <- function(..., env = parent.frame()) {
    files <- c(...)
    dir <- withr::local_tempdir(.local_envir = env)
    for (f in files) {
        fs::dir_create(fs::path_dir(fs::path_join(c(dir, f))))
        writeLines("not really an image", fs::path_join(c(dir, f)))
    }
    dir
}

test_that(".find_logo returns NULL when the package has no logo", {
    expect_null(.find_logo(local_logo_package()))
    # A non-logo image in man/figures is not a logo.
    expect_null(.find_logo(local_logo_package("man/figures/README-plot.png")))
})

test_that(".find_logo finds a logo in either location", {
    expect_identical(
        basename(.find_logo(local_logo_package("logo.png"))),
        "logo.png"
    )
    expect_identical(
        basename(.find_logo(local_logo_package("man/figures/logo.png"))),
        "logo.png"
    )
})

test_that(".find_logo prefers .svg, and the root over man/figures", {
    # Both extensions in the same place: .svg wins because it scales.
    dir <- local_logo_package("logo.png", "logo.svg")
    expect_identical(basename(.find_logo(dir)), "logo.svg")

    # Both locations, same extension: the root wins.
    dir <- local_logo_package("logo.png", "man/figures/logo.png")
    expect_identical(
        .find_logo(dir),
        unname(fs::path_join(c(dir, "logo.png")))
    )

    # The full order: a root .svg beats a man/figures .svg, which beats a
    # root .png, which beats a man/figures .png.
    dir <- local_logo_package(
        "logo.svg",
        "man/figures/logo.svg",
        "logo.png",
        "man/figures/logo.png"
    )
    expect_identical(
        .find_logo(dir),
        unname(fs::path_join(c(dir, "logo.svg")))
    )

    dir <- local_logo_package("man/figures/logo.svg", "logo.png")
    expect_identical(
        .find_logo(dir),
        unname(fs::path_join(c(dir, "man/figures/logo.svg")))
    )
})

test_that(".import_logo copies the logo and reports its name", {
    dir <- local_logo_package("man/figures/logo.svg")
    tar_dir <- fs::path_join(c(dir, "docs"))
    fs::dir_create(tar_dir)

    expect_message(out <- .import_logo(dir, tar_dir), "logo.svg")
    expect_identical(out, "logo.svg")
    # Copied to the site root under its own name, not renamed, so the
    # `$ALTDOC_LOGO` substitution resolves to a file that exists.
    expect_true(fs::file_exists(fs::path_join(c(tar_dir, "logo.svg"))))
})

test_that(".import_logo is a no-op for a package with no logo", {
    dir <- local_logo_package()
    tar_dir <- fs::path_join(c(dir, "docs"))
    fs::dir_create(tar_dir)

    expect_null(.import_logo(dir, tar_dir))
    expect_length(fs::dir_ls(tar_dir), 0)
})

test_that("$ALTDOC_LOGO resolves when the logo was imported", {
    dir <- local_logo_package("man/figures/logo.png")
    fs::dir_create(fs::path_join(c(dir, "docs")))
    .import_logo(dir, fs::path_join(c(dir, "docs"))) |> suppressMessages()

    expect_identical(
        .substitute_altdoc_variables("logo: $ALTDOC_LOGO", path = dir),
        "logo: logo.png"
    )
    # docute serves from the site root, so its paths are absolute, matching
    # how the file variables above are substituted for that tool.
    expect_identical(
        .substitute_altdoc_variables(
            "logo: $ALTDOC_LOGO",
            path = dir,
            tool = "docute"
        ),
        "logo: /logo.png"
    )
})

test_that("$ALTDOC_LOGO drops its line when there is no logo", {
    dir <- local_logo_package()
    fs::dir_create(fs::path_join(c(dir, "docs")))

    expect_length(
        .substitute_altdoc_variables("logo: $ALTDOC_LOGO", path = dir),
        0
    )
})

test_that("$ALTDOC_LOGO drops its line when the logo was never imported", {
    # The package has a logo but `docs/` does not, which is what a settings
    # file substituted before the copy would see. A stale reference here
    # would point the generator at a file that is not in the site.
    dir <- local_logo_package("logo.png")
    fs::dir_create(fs::path_join(c(dir, "docs")))

    expect_length(
        .substitute_altdoc_variables("logo: $ALTDOC_LOGO", path = dir),
        0
    )
})
