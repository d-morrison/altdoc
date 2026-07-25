test_that(".rd_topics reads name, title, and internal status from man/", {
    topics <- .rd_topics(testthat::test_path("examples/testpkg.altdoc"))

    expect_identical(
        topics$name,
        c("examplesIf_false", "examplesIf_true", "hello_base", "hello_r6")
    )
    expect_identical(
        topics$title[topics$name == "hello_base"],
        "Base function"
    )
    expect_false(any(topics$internal))
})

test_that(".rd_topics reports no topics when man/ is absent or empty", {
    expect_identical(nrow(.rd_topics(withr::local_tempdir())), 0L)
})

test_that(".rd_topics flags internal topics", {
    dir <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(dir, "man")))
    fs::file_copy(
        testthat::test_path("examples/examples-man/is-internal.Rd"),
        fs::path_join(c(dir, "man", "is-internal.Rd"))
    )

    topics <- .rd_topics(dir)
    expect_identical(topics$internal, TRUE)
})

test_that(".rd_is_function distinguishes functions from other topics", {
    topics <- .rd_topics(testthat::test_path("examples/testpkg.altdoc"))

    # hello_r6 is an R6 generator: it has no \usage{}, so it is not a call.
    expect_identical(topics$is_fun[topics$name == "hello_base"], TRUE)
    expect_identical(topics$is_fun[topics$name == "hello_r6"], FALSE)
})
