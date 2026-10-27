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
        c("---", "title: Articles Intro", "---"),
        fs::path_join(c(dir, "vignettes", "articles", "intro.qmd"))
    )
    writeLines(
        c("---", "title: Tutorials Intro", "---"),
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
        c("---", 'title: "Getting Started"', "---"),
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

test_that(".get_vignettes_titles falls back to H1 header or filename when no YAML title", {
    dir <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(dir, "vignettes")))
    fs::dir_create(fs::path_join(c(dir, "docs", "vignettes")), recurse = TRUE)

    # Vignette with no YAML front matter, but H1 in rendered .md
    writeLines("no front matter", fs::path_join(c(dir, "vignettes", "no_front.Rmd")))
    writeLines("# H1 Title Header", fs::path_join(c(dir, "docs", "vignettes", "no_front.md")))

    expect_equal(
        .get_vignettes_titles(
            fs::path_join(c(dir, "docs", "vignettes", "no_front.md")),
            path = dir
        ),
        "H1 Title Header"
    )

    # Vignette with no YAML and no H1 header -> formatted filename fallback
    writeLines("no front matter", fs::path_join(c(dir, "vignettes", "my_cool_vignette.Rmd")))
    writeLines("just text", fs::path_join(c(dir, "docs", "vignettes", "my_cool_vignette.md")))

    expect_equal(
        .get_vignettes_titles(
            fs::path_join(c(dir, "docs", "vignettes", "my_cool_vignette.md")),
            path = dir
        ),
        "My Cool Vignette"
    )
})
