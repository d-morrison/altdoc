test_that("the default index lists every non-internal topic", {
    pkg <- testthat::test_path("examples/testpkg.altdoc")
    topics <- .rd_topics(pkg)

    sections <- .reference_sections(.reference_settings(pkg), topics)

    out <- .reference_index(sections, topics)

    expect_identical(out[1], "# Package index")
    expect_true("## All functions" %in% out)
    expect_true(
        "- [`hello_base()`](man/hello_base.md) --- Base function" %in% out
    )
})

test_that("man page links follow the generator's own file extension", {
    pkg <- testthat::test_path("examples/testpkg.altdoc")
    topics <- .rd_topics(pkg)
    sections <- .reference_sections(.reference_settings(pkg), topics)

    out <- .reference_index(sections, topics, ext = "qmd")
    expect_true(
        "- [`hello_base()`](man/hello_base.qmd) --- Base function" %in% out
    )
})

test_that("a mangled topic links to its page and is labelled by its name", {
    # The label and the link target come from different columns, and every
    # other fixture in this file documents topics whose names are already
    # filesystem-safe -- so the two columns hold the same string and a link
    # built from the wrong one still resolves. Only a mangled topic separates
    # them.
    dir <- local_man_package(
        `grapes-plus-grapes` = c(
            "\\name{\\%+\\%}",
            "\\alias{\\%+\\%}",
            "\\title{Concatenate strings}",
            "\\description{d}"
        )
    )
    topics <- .rd_topics(dir)
    sections <- .reference_sections(.reference_settings(dir), topics)

    out <- .reference_index(sections, topics)

    expect_true(
        "- [`%+%`](man/grapes-plus-grapes.md) --- Concatenate strings" %in% out
    )
})

test_that(".import_reference counts the topics the page lists", {
    # Every documented topic is not the same number as every listed one, so a
    # fixture with no internal topic cannot tell the two counts apart.
    dir <- local_man_package(
        pub = c(
            "\\name{pub}",
            "\\alias{pub}",
            "\\title{A public topic}",
            "\\description{d}"
        ),
        helper = c(
            "\\name{helper}",
            "\\alias{helper}",
            "\\title{An internal helper}",
            "\\description{d}",
            "\\keyword{internal}"
        )
    )
    tar_dir <- fs::path_join(c(dir, "docs"))
    fs::dir_create(tar_dir)

    expect_message(
        .import_reference(src_dir = dir, tar_dir = tar_dir),
        "written with 1 topic\\."
    )
})

test_that("altdoc/reference.yml supplies the grouping", {
    dir <- local_reference_package(
        "reference:",
        "  - title: Examples",
        "    desc: The examplesIf topics.",
        "    contents:",
        "      - starts_with(\"examplesIf\")",
        "  - title: Greetings",
        "    subtitle: Base and R6",
        "    contents:",
        "      - hello_base",
        "      - hello_dontrun",
        "      - hello_r6"
    )
    topics <- .rd_topics(dir)

    sections <- .reference_sections(.reference_settings(dir), topics)

    out <- .reference_index(sections, topics)

    expect_identical(
        out,
        c(
            "# Package index",
            "",
            "## Examples",
            "",
            "The examplesIf topics.",
            "",
            "- [`examplesIf_false()`](man/examplesIf_false.md) --- Examples If FALSE",
            "- [`examplesIf_true()`](man/examplesIf_true.md) --- Examples If TRUE",
            "",
            "## Greetings",
            "",
            "### Base and R6",
            "",
            "- [`hello_base()`](man/hello_base.md) --- Base function",
            "- [`hello_dontrun()`](man/hello_dontrun.md) --- Mixed runnable and non-runnable examples",
            "- [`hello_r6`](man/hello_r6.md) --- Create a \"conductor\" tour",
            ""
        )
    )
})

test_that("topics missing from the config are warned about and still listed", {
    dir <- local_reference_package(
        "reference:",
        "  - title: Greetings",
        "    contents:",
        "      - starts_with(\"hello\")"
    )
    topics <- .rd_topics(dir)
    sections <- .reference_sections(.reference_settings(dir), topics)

    expect_message(
        out <- .reference_index(sections, topics),
        "2 topics missing"
    )

    expect_true("## Other" %in% out)
    expect_true(
        "- [`examplesIf_true()`](man/examplesIf_true.md) --- Examples If TRUE" %in%
            out
    )
})

test_that("an unknown key in altdoc/reference.yml is an error", {
    dir <- local_reference_package(
        "reference:",
        "  - titel: Typo",
        "    contents:",
        "      - hello_base"
    )
    topics <- .rd_topics(dir)

    expect_error(
        .reference_sections(.reference_settings(dir), topics),
        "Unknown key"
    )
})

test_that("an unknown topic in altdoc/reference.yml is an error", {
    dir <- local_reference_package(
        "reference:",
        "  - title: Greetings",
        "    contents:",
        "      - no_such_topic"
    )
    topics <- .rd_topics(dir)
    sections <- .reference_sections(.reference_settings(dir), topics)

    expect_error(
        .reference_index(sections, topics),
        "not a known topic name or alias"
    )
})

test_that("the index heading defaults to Package index", {
    dir <- local_reference_package(
        "reference:",
        "  - title: Greetings",
        "    contents:",
        "      - starts_with(\"hello\")"
    )

    expect_identical(
        .reference_title(.reference_settings(dir)),
        "Package index"
    )
})

test_that("a package with no altdoc/reference.yml still gets the default heading", {
    pkg <- testthat::test_path("examples/testpkg.altdoc")

    expect_identical(
        .reference_title(.reference_settings(pkg)),
        "Package index"
    )
})

test_that("altdoc/reference.yml can override the index heading", {
    dir <- local_reference_package(
        "title: Function reference",
        "reference:",
        "  - title: Greetings",
        "    contents:",
        "      - starts_with(\"hello\")"
    )
    topics <- .rd_topics(dir)
    settings <- .reference_settings(dir)
    sections <- .reference_sections(settings, topics)

    expect_identical(.reference_title(settings), "Function reference")

    suppressMessages(
        out <- .reference_index(
            sections,
            topics,
            title = .reference_title(settings)
        )
    )
    expect_identical(out[1], "# Function reference")
})

test_that("a title with no reference: key still groups topics by default", {
    dir <- local_reference_package("title: Function reference")
    topics <- .rd_topics(dir)
    settings <- .reference_settings(dir)

    expect_identical(.reference_title(settings), "Function reference")
    expect_true(
        "All functions" %in%
            vapply(
                .reference_sections(settings, topics),
                function(section) section$title,
                character(1)
            )
    )
})

# One `test_that()` per rejected shape, so a failure names the shape in its own
# heading. A single loop over the three would report only that no error was
# thrown, leaving the reader to guess which input did it; `expect_error()`'s
# `info` is soft-deprecated and `label` replaces the expression under test
# rather than adding to it, so neither is the way to label the cases.
expect_unusable_title <- function(...) {
    dir <- local_reference_package(..., env = parent.frame())
    expect_error(.reference_title(.reference_settings(dir)), "title|must")
}

test_that("an empty-sequence title in altdoc/reference.yml is an error", {
    expect_unusable_title("title: []")
})

test_that("an empty-string title in altdoc/reference.yml is an error", {
    expect_unusable_title("title: ''")
})

test_that("a multi-value title in altdoc/reference.yml is an error", {
    expect_unusable_title("title:", "  - a", "  - b")
})

test_that("an unknown top-level key in altdoc/reference.yml is an error", {
    dir <- local_reference_package(
        "titel: Typo",
        "reference:",
        "  - title: Greetings",
        "    contents:",
        "      - starts_with(\"hello\")"
    )

    expect_error(.reference_settings(dir), "Unknown top-level key")
})

test_that("a bare pkgdown-style section list is still accepted", {
    dir <- local_reference_package(
        "- title: Greetings",
        "  contents:",
        "    - starts_with(\"hello\")"
    )
    settings <- .reference_settings(dir)

    expect_null(settings$title)
    expect_identical(.reference_title(settings), "Package index")
    expect_length(settings$sections, 1L)
})
