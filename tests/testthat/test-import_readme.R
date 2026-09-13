# A throwaway package root holding the given README files, passed as
# "README.md" = c("<line>", ...), plus the docs/ and altdoc/ dirs
# .import_readme() writes into.
local_readme_package <- function(..., env = parent.frame()) {
    files <- list(...)
    dir <- withr::local_tempdir(.local_envir = env)
    fs::dir_create(fs::path_join(c(dir, "docs")))
    fs::dir_create(fs::path_join(c(dir, "altdoc")))
    for (nm in names(files)) {
        writeLines(files[[nm]], fs::path_join(c(dir, nm)))
    }
    dir
}

test_that(".import_readme copies README.md, whatever variants sit beside it", {
    dir <- local_readme_package(
        "README.md" = "# from the md",
        "README.qmd" = "# from the qmd"
    )
    withr::local_dir(dir)

    expect_message(
        .import_readme(dir, fs::path_join(c(dir, "docs")), "docute", FALSE),
        "imported"
    )

    # `README.qmd` has "priority" in the sense that the author edits it, but
    # altdoc never renders it, so the copied file is always `README.md` (#69).
    expect_identical(
        .readlines(fs::path_join(c(dir, "docs", "README.md"))),
        "# from the md"
    )
})

test_that(".import_readme errors when README.md is absent", {
    dir <- local_readme_package("README.qmd" = "# only a qmd")
    withr::local_dir(dir)

    expect_error(
        .import_readme(dir, fs::path_join(c(dir, "docs")), "docute", FALSE),
        "README.md is mandatory"
    )
})

test_that("quarto_website gets index.qmd including README.qmd when README.qmd is present", {
    dir <- local_readme_package(
        "README.md" = "# readme",
        "README.qmd" = "# readme qmd"
    )
    withr::local_dir(dir)
    tar_dir <- fs::path_join(c(dir, "docs"))

    suppressMessages(.import_readme(dir, tar_dir, "quarto_website", FALSE))

    expect_true(fs::file_exists(fs::path_join(c(tar_dir, "index.qmd"))))
    expect_true(fs::file_exists(fs::path_join(c(tar_dir, "README.qmd"))))
    expect_false(fs::file_exists(fs::path_join(c(tar_dir, "index.md"))))
    expect_identical(
        .readlines(fs::path_join(c(tar_dir, "index.qmd"))),
        "{{< include README.qmd >}}"
    )
})

test_that("quarto_website gets index.md including README.md when README.qmd is absent", {
    dir <- local_readme_package(
        "README.md" = "# readme"
    )
    withr::local_dir(dir)
    tar_dir <- fs::path_join(c(dir, "docs"))

    suppressMessages(.import_readme(dir, tar_dir, "quarto_website", FALSE))

    expect_true(fs::file_exists(fs::path_join(c(tar_dir, "index.md"))))
    expect_false(fs::file_exists(fs::path_join(c(tar_dir, "index.qmd"))))
    expect_identical(
        .readlines(fs::path_join(c(tar_dir, "index.md"))),
        "{{< include README.md >}}"
    )
})

test_that("freeze skips an unchanged README.md", {
    dir <- local_readme_package("README.md" = "# readme")
    withr::local_dir(dir)
    tar_dir <- fs::path_join(c(dir, "docs"))

    suppressMessages(.import_readme(dir, tar_dir, "docute", TRUE))
    expect_message(
        .import_readme(dir, tar_dir, "docute", TRUE),
        "didn't change"
    )
})

test_that("freeze skips an unchanged README.md beside a README.qmd", {
    # The bug #69 reports. `.is_frozen()` was handed the preferred variant
    # ("README.qmd"), a key `.update_freeze()` never wrote, so
    # `input %in% names(hashes)` was always FALSE and freeze never skipped the
    # README for any package shipping a .qmd or .Rmd. The package below is
    # identical to the one in the previous test except for that .qmd, which is
    # what makes this the case that distinguishes the two behaviours.
    dir <- local_readme_package(
        "README.md" = "# readme",
        "README.qmd" = "# readme qmd"
    )
    withr::local_dir(dir)
    tar_dir <- fs::path_join(c(dir, "docs"))

    suppressMessages(.import_readme(dir, tar_dir, "docute", TRUE))
    expect_message(
        .import_readme(dir, tar_dir, "docute", TRUE),
        "didn't change"
    )
})

test_that("freeze re-copies when README.md changes beside an unchanged qmd", {
    # The bug #69 describes: `.is_frozen()` looked up the preferred variant
    # ("README.qmd"), a key `.update_freeze()` never wrote. Recording that
    # variant instead would have been worse than the mismatch -- altdoc copies
    # `README.md`, so keying the skip on a file it never reads lets an edit
    # made directly to `README.md` go undetected and leaves docs/ stale.
    dir <- local_readme_package(
        "README.md" = "# first",
        "README.qmd" = "# readme qmd"
    )
    withr::local_dir(dir)
    tar_dir <- fs::path_join(c(dir, "docs"))

    suppressMessages(.import_readme(dir, tar_dir, "docute", TRUE))

    # Edit README.md only; README.qmd is deliberately left untouched.
    writeLines("# second", fs::path_join(c(dir, "README.md")))
    suppressMessages(.import_readme(dir, tar_dir, "docute", TRUE))

    expect_identical(
        .readlines(fs::path_join(c(tar_dir, "README.md"))),
        "# second"
    )
})

test_that(".get_hashes returns the hashes it read, visibly", {
    dir <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(dir, "altdoc")))

    expect_null(.get_hashes(dir, freeze = FALSE))
    # No freeze file yet.
    expect_null(.get_hashes(dir, freeze = TRUE))

    hashes <- c(a = "one", b = "two")
    saveRDS(hashes, fs::path_join(c(dir, "altdoc", "freeze.rds")))
    expect_identical(.get_hashes(dir, freeze = TRUE), hashes)

    # The value assertions above hold against the pre-fix function too: it
    # returned these same values, just *invisibly*, because its last
    # expression was the `if` block rather than a `return()`. Visibility is
    # the only thing the explicit return changes, so it is the only thing
    # that can pin it (#69).
    expect_true(withVisible(.get_hashes(dir, freeze = TRUE))$visible)
    expect_true(withVisible(.get_hashes(dir, freeze = FALSE))$visible)
})
