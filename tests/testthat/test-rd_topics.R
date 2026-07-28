test_that(".rd_topics reads name, title, and internal status from man/", {
    topics <- .rd_topics(testthat::test_path("examples/testpkg.altdoc"))

    expect_identical(
        topics$name,
        c(
            "examplesIf_false",
            "examplesIf_true",
            "hello_base",
            "hello_dontrun",
            "hello_r6"
        )
    )
    expect_identical(
        topics$title[topics$name == "hello_base"],
        "Base function"
    )
    expect_false(any(topics$internal))
})

test_that(".rd_topics records the .Rd basename alongside the topic name", {
    # roxygen2 mangles the file name of a topic whose name is not
    # filesystem-safe, so `name` and `file` diverge and each is needed for a
    # different job: `name` labels the topic, `file` locates its page. An
    # ordinary topic is included to pin that the two agree when nothing was
    # mangled -- a fixture of only mangled topics could not tell the columns
    # apart from each other.
    dir <- local_man_package(
        `grapes-plus-grapes` = c(
            "\\name{\\%+\\%}",
            "\\alias{\\%+\\%}",
            "\\title{Concatenate strings}",
            "\\description{d}"
        ),
        `sub-.myclass` = c(
            "\\name{[.myclass}",
            "\\alias{[.myclass}",
            "\\title{Subset a myclass object}",
            "\\description{d}"
        ),
        hello = c(
            "\\name{hello}",
            "\\alias{hello}",
            "\\title{Say hello}",
            "\\description{d}"
        )
    )

    topics <- .rd_topics(dir)

    expect_identical(topics$name, c("%+%", "[.myclass", "hello"))
    expect_identical(
        topics$file,
        c("grapes-plus-grapes", "sub-.myclass", "hello")
    )
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
