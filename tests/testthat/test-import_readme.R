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

test_that(".import_readme copies README.md when present", {
    dir <- local_readme_package(
        "README.md" = "# from the md",
        "README.qmd" = "# from the qmd"
    )
    withr::local_dir(dir)

    expect_message(
        .import_readme(dir, fs::path_join(c(dir, "docs")), "docute", FALSE),
        "imported"
    )

    expect_identical(
        .readlines(fs::path_join(c(dir, "docs", "README.md"))),
        "# from the md"
    )
})

test_that(".import_readme errors when all README variants are absent", {
    dir <- local_readme_package("OTHER.md" = "# unrelated")
    withr::local_dir(dir)

    expect_error(
        .import_readme(dir, fs::path_join(c(dir, "docs")), "docute", FALSE),
        "README file is mandatory"
    )
})

test_that(".import_readme works when only README.qmd is present", {
    dir <- local_readme_package("README.qmd" = "# only qmd")
    withr::local_dir(dir)

    expect_message(
        .import_readme(dir, fs::path_join(c(dir, "docs")), "docute", FALSE),
        "imported"
    )

    expect_identical(
        .readlines(fs::path_join(c(dir, "docs", "README.md"))),
        "# only qmd"
    )
})

test_that("quarto_website uses README.qmd and creates index.qmd when README.qmd is present", {
    dir <- local_readme_package(
        "README.md" = "# readme",
        "README.qmd" = "# readme qmd"
    )
    withr::local_dir(dir)
    tar_dir <- fs::path_join(c(dir, "docs"))

    suppressMessages(.import_readme(dir, tar_dir, "quarto_website", FALSE))

    expect_true(fs::file_exists(fs::path_join(c(tar_dir, "index.qmd"))))
    expect_true(fs::file_exists(fs::path_join(c(tar_dir, "README.qmd"))))
    expect_identical(
        .readlines(fs::path_join(c(tar_dir, "index.qmd"))),
        "{{< include README.qmd >}}"
    )
})

test_that("quarto_website uses README.md and creates index.md when README.qmd is absent", {
    dir <- local_readme_package(
        "README.md" = "# readme md only"
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

test_that("freeze skips an unchanged README.md beside a README.qmd for non-quarto tool", {
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

test_that("freeze re-copies when README.md changes beside an unchanged qmd for non-quarto tool", {
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

    expect_true(withVisible(.get_hashes(dir, freeze = TRUE))$visible)
    expect_true(withVisible(.get_hashes(dir, freeze = FALSE))$visible)
})
