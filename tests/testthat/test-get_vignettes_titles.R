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

test_that(".get_vignettes_titles handles vig_root when paths contain vignettes segments", {
    base_dir <- withr::local_tempdir()

    # Case 1: Ancestor directory named 'vignettes'
    dir1 <- fs::path_join(c(base_dir, "vignettes", "pkg"))
    fs::dir_create(fs::path_join(c(dir1, "vignettes")), recurse = TRUE)
    vig_root1 <- fs::path_join(c(dir1, "docs", "vignettes"))
    fs::dir_create(vig_root1, recurse = TRUE)

    writeLines(
        c("---", "out: Ancestor Vignettes Title", "---"),
        fs::path_join(c(dir1, "vignettes", "intro.qmd"))
    )
    fn1 <- fs::path_join(c(vig_root1, "intro.md"))
    writeLines("some content", fn1)

    expect_equal(
        .get_vignettes_titles(fn1, path = dir1, vig_root = vig_root1),
        "Ancestor Vignettes Title"
    )

    # Case 2: Subdirectory named 'vignettes'
    dir2 <- fs::path_join(c(base_dir, "pkg2"))
    fs::dir_create(fs::path_join(c(dir2, "vignettes", "vignettes")), recurse = TRUE)
    vig_root2 <- fs::path_join(c(dir2, "docs", "vignettes"))
    fs::dir_create(fs::path_join(c(vig_root2, "vignettes")), recurse = TRUE)

    writeLines(
        c("---", "out: Nested Vignettes Folder Title", "---"),
        fs::path_join(c(dir2, "vignettes", "vignettes", "intro.qmd"))
    )
    fn2 <- fs::path_join(c(vig_root2, "vignettes", "intro.md"))
    writeLines("some content", fn2)

    expect_equal(
        .get_vignettes_titles(fn2, path = dir2, vig_root = vig_root2),
        "Nested Vignettes Folder Title"
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
