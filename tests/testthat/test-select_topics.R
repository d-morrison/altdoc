test_that(".select_topics resolves bare topic names", {
    topics <- .rd_topics(testthat::test_path("examples/testpkg.altdoc"))

    expect_identical(
        selected_names(list("hello_base", "hello_r6"), topics),
        c("hello_base", "hello_r6")
    )
})

test_that(".select_topics supports the string selectors", {
    topics <- .rd_topics(testthat::test_path("examples/testpkg.altdoc"))

    expect_identical(
        selected_names(list("starts_with(\"examplesIf\")"), topics),
        c("examplesIf_false", "examplesIf_true")
    )
    expect_identical(
        selected_names(list("ends_with(\"_r6\")"), topics),
        "hello_r6"
    )
    expect_identical(
        selected_names(list("matches(\"^hello\")"), topics),
        c("hello_base", "hello_r6")
    )
    expect_identical(
        selected_names(list("contains(\"_ba\")"), topics),
        "hello_base"
    )
})

test_that(".select_topics removes topics with a leading minus", {
    topics <- .rd_topics(testthat::test_path("examples/testpkg.altdoc"))

    # A leading removal starts from every non-internal topic.
    expect_identical(
        selected_names(list("-starts_with(\"examplesIf\")"), topics),
        c("hello_base", "hello_r6")
    )
    # A removal after an addition narrows what was added.
    expect_identical(
        selected_names(list("everything()", "-hello_r6"), topics),
        c("examplesIf_false", "examplesIf_true", "hello_base")
    )
})

test_that(".select_topics keeps internal topics out unless asked", {
    dir <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(dir, "man")))
    fs::file_copy(
        testthat::test_path("examples/examples-man/is-internal.Rd"),
        fs::path_join(c(dir, "man", "is-internal.Rd"))
    )
    topics <- .rd_topics(dir)

    expect_identical(selected_names(list("everything()"), topics), character(0))
    expect_identical(
        selected_names(list("everything(internal = TRUE)"), topics),
        topics$name
    )
})

test_that(".select_topics rejects a mix of additions and removals", {
    topics <- .rd_topics(testthat::test_path("examples/testpkg.altdoc"))

    expect_error(
        .select_topics(list("c(1, -2)"), topics),
        "Cannot mix selected and de-selected"
    )
})
