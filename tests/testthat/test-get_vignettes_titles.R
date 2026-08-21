test_that(".get_vignettes_titles addresses a nested source by path, not by name", {
    dir <- withr::local_tempdir()
    for (sub in c("articles", "tutorials")) {
        fs::dir_create(fs::path_join(c(dir, "vignettes", sub)), recurse = TRUE)
        fs::dir_create(
            fs::path_join(c(dir, "docs", "vignettes", sub)),
            recurse = TRUE
        )
    }

    # Two vignettes sharing a basename in different subdirectories, which is
    # only reachable once nested vignettes are rendered at all. Searching for
    # the name returns both, so the `length(p) == 1` guard gives up and the
    # title silently degrades to the file name; addressing the source by its
    # path returns exactly one.
    writeLines(
        c("---", "out: Articles Intro", "---"),
        fs::path_join(c(dir, "vignettes", "articles", "intro.qmd"))
    )
    writeLines(
        c("---", "out: Tutorials Intro", "---"),
        fs::path_join(c(dir, "vignettes", "tutorials", "intro.qmd"))
    )
    for (sub in c("articles", "tutorials")) {
        writeLines(
            "some body text",
            fs::path_join(c(dir, "docs", "vignettes", sub, "intro.md"))
        )
    }

    expect_equal(
        .get_vignettes_titles(
            fs::path_join(c(dir, "docs", "vignettes", "articles", "intro.md")),
            path = dir
        ),
        "Articles Intro"
    )
    expect_equal(
        .get_vignettes_titles(
            fs::path_join(c(dir, "docs", "vignettes", "tutorials", "intro.md")),
            path = dir
        ),
        "Tutorials Intro"
    )
})

test_that(".get_vignettes_titles still resolves a top-level vignette", {
    dir <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(dir, "vignettes")))
    fs::dir_create(fs::path_join(c(dir, "docs", "vignettes")), recurse = TRUE)

    writeLines(
        c("---", "out: Getting Started", "---"),
        fs::path_join(c(dir, "vignettes", "start.Rmd"))
    )
    writeLines(
        "some body text",
        fs::path_join(c(dir, "docs", "vignettes", "start.md"))
    )

    expect_equal(
        .get_vignettes_titles(
            fs::path_join(c(dir, "docs", "vignettes", "start.md")),
            path = dir
        ),
        "Getting Started"
    )
})

test_that(".get_vignettes_titles handles paths where an ancestor directory is named 'vignettes'", {
    base_dir <- withr::local_tempdir()
    dir <- fs::path_join(c(base_dir, "vignettes", "pkg"))
    fs::dir_create(fs::path_join(c(dir, "vignettes")), recurse = TRUE)
    fs::dir_create(fs::path_join(c(dir, "docs", "vignettes")), recurse = TRUE)

    writeLines(
        c("---", "out: Ancestor Test", "---"),
        fs::path_join(c(dir, "vignettes", "start.Rmd"))
    )
    writeLines(
        "some body text",
        fs::path_join(c(dir, "docs", "vignettes", "start.md"))
    )

    vig_root <- fs::path_join(c(dir, "docs", "vignettes"))
    expect_equal(
        .get_vignettes_titles(
            fs::path_join(c(dir, "docs", "vignettes", "start.md")),
            path = dir,
            vig_root = vig_root
        ),
        "Ancestor Test"
    )
})

test_that(".get_vignettes_titles handles nested subdirectories named 'vignettes'", {
    dir <- withr::local_tempdir()
    fs::dir_create(
        fs::path_join(c(dir, "vignettes", "vignettes")),
        recurse = TRUE
    )
    fs::dir_create(
        fs::path_join(c(dir, "docs", "vignettes", "vignettes")),
        recurse = TRUE
    )

    writeLines(
        c("---", "out: Nested Vignettes Folder", "---"),
        fs::path_join(c(dir, "vignettes", "vignettes", "intro.qmd"))
    )
    writeLines(
        "some body text",
        fs::path_join(c(dir, "docs", "vignettes", "vignettes", "intro.md"))
    )

    vig_root <- fs::path_join(c(dir, "docs", "vignettes"))
    expect_equal(
        .get_vignettes_titles(
            fs::path_join(c(dir, "docs", "vignettes", "vignettes", "intro.md")),
            path = dir,
            vig_root = vig_root
        ),
        "Nested Vignettes Folder"
    )
})
