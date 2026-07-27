test_that(".rd2qmd works", {
    # .rd2qmd works only in pkg directory
    rd_file <- fs::path_abs(
        testthat::test_path("examples/examples-man/between.Rd")
    )
    create_local_package()
    setup_docs("docute")
    fs::file_copy(rd_file, ".")
    fs::dir_create("docs")
    .rd2qmd(rd_file, "docs", path = ".")
    qmd_file <- fs::path_join(c("docs", "between.qmd"))
    expect_true(fs::file_exists(qmd_file))

    content <- .readlines(qmd_file)
    h3 <- grep("^### ", content, value = TRUE)
    expect_identical(h3, c("### Description", "### Usage", "### Arguments"))

    h2 <- grep("^## ", content, value = TRUE)
    expect_identical(
        h2,
        "## Do values in a numeric vector fall in specified range? {.unnumbered}"
    )
})

test_that(".rd2qmd: basic errors", {
    expect_error(
        .rd2qmd("foo"),
        "must be a valid file path"
    )
    # The guards are anchored on the argument name, not just on "must be a
    # valid directory", since `target_dir` and `path` now share that wording
    # and an unanchored match cannot tell which one fired.
    expect_error(
        .rd2qmd(
            testthat::test_path("examples/examples-man/between.Rd"),
            "foo",
            path = "."
        ),
        "^target_dir must be a valid directory"
    )
    # A missing `target_dir` reports the same error as an invalid one, rather
    # than R's own "argument is missing, with no default" (#62).
    expect_error(
        .rd2qmd(testthat::test_path("examples/examples-man/between.Rd")),
        "^target_dir must be a valid directory"
    )
    expect_error(
        .rd2qmd(
            testthat::test_path("examples/examples-man/between.Rd"),
            testthat::test_path("examples/examples-man"),
            path = "foo"
        ),
        "^path must be a valid directory"
    )
    # Same for a missing `path`, which otherwise reached `.doc_type()` and
    # failed there with R's own 'argument "path" is missing, with no
    # default' (#64).
    expect_error(
        .rd2qmd(
            testthat::test_path("examples/examples-man/between.Rd"),
            testthat::test_path("examples/examples-man")
        ),
        "^path must be a valid directory"
    )
})

test_that(".rd2qmd: title across several lines", {
    rd_file <- fs::path_abs(
        testthat::test_path("examples/examples-man/long_title.Rd")
    )
    create_local_package()
    setup_docs("docute")
    fs::file_copy(rd_file, ".")
    fs::dir_create("docs")
    .rd2qmd(rd_file, "docs", path = ".")
    expect_snapshot_file("docs/long_title.qmd")
})
