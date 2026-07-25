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

test_that(".select_topics supports the keyword and concept selectors", {
    dir <- local_man_package(
        fit = c(
            "\\name{fit}",
            "\\alias{fit}",
            "\\title{Fit a model}",
            "\\usage{fit(x)}",
            "\\concept{estimation}",
            "\\keyword{models}",
            "\\description{d}"
        ),
        predict_it = c(
            "\\name{predict_it}",
            "\\alias{predict_it}",
            "\\title{Predict from a model}",
            "\\usage{predict_it(x)}",
            "\\concept{estimation}",
            "\\description{d}"
        ),
        plot_it = c(
            "\\name{plot_it}",
            "\\alias{plot_it}",
            "\\title{Plot a model}",
            "\\usage{plot_it(x)}",
            "\\concept{graphics}",
            "\\description{d}"
        )
    )
    topics <- .rd_topics(dir)

    expect_identical(
        selected_names(list("has_concept(\"estimation\")"), topics),
        c("fit", "predict_it")
    )
    expect_identical(
        selected_names(list("has_keyword(\"models\")"), topics),
        "fit"
    )
    expect_identical(
        selected_names(list("lacks_concepts(\"estimation\")"), topics),
        "plot_it"
    )
    # `lacks_concept` is accepted as a synonym, as in pkgdown.
    expect_identical(
        selected_names(list("lacks_concept(\"estimation\")"), topics),
        "plot_it"
    )
})

test_that("the keyword and concept selectors skip internal topics", {
    dir <- local_man_package(
        shown = c(
            "\\name{shown}",
            "\\alias{shown}",
            "\\title{Shown}",
            "\\concept{estimation}",
            "\\description{d}"
        ),
        hidden = c(
            "\\name{hidden}",
            "\\alias{hidden}",
            "\\title{Hidden}",
            "\\concept{estimation}",
            "\\keyword{internal}",
            "\\description{d}"
        )
    )
    topics <- .rd_topics(dir)

    expect_identical(
        selected_names(list("has_concept(\"estimation\")"), topics),
        "shown"
    )
    expect_identical(
        selected_names(
            list("has_concept(\"estimation\", internal = TRUE)"),
            topics
        ),
        c("hidden", "shown")
    )
})
