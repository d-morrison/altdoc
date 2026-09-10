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

test_that(".get_vignettes_titles resolves correctly when ancestor path contains 'vignettes'", {
    base_dir <- withr::local_tempdir()
    # Create directory tree with ancestor path segment named "vignettes"
    dir <- fs::path_join(c(base_dir, "vignettes", "my_package"))
    vig_src <- fs::path_join(c(dir, "vignettes"))
    vig_pub <- fs::path_join(c(dir, "docs", "vignettes"))
    fs::dir_create(vig_src, recurse = TRUE)
    fs::dir_create(vig_pub, recurse = TRUE)

    writeLines(
        c("---", "out: Ancestor Test Title", "---"),
        fs::path_join(c(vig_src, "test.qmd"))
    )
    writeLines(
        "some body text",
        fs::path_join(c(vig_pub, "test.md"))
    )

    expect_equal(
        .get_vignettes_titles(
            fs::path_join(c(vig_pub, "test.md")),
            path = dir,
            vig_root = vig_pub
        ),
        "Ancestor Test Title"
    )
})
