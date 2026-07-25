test_that("the default index lists every non-internal topic", {
    pkg <- testthat::test_path("examples/testpkg.altdoc")
    topics <- .rd_topics(pkg)

    out <- .reference_index(.reference_sections(pkg, topics), topics)

    expect_identical(out[1], "# Reference")
    expect_true("## All functions" %in% out)
    expect_true(
        "- [`hello_base()`](man/hello_base.md) --- Base function" %in% out
    )
})

test_that("man page links follow the generator's own file extension", {
    pkg <- testthat::test_path("examples/testpkg.altdoc")
    topics <- .rd_topics(pkg)
    sections <- .reference_sections(pkg, topics)

    out <- .reference_index(sections, topics, ext = "qmd")
    expect_true(
        "- [`hello_base()`](man/hello_base.qmd) --- Base function" %in% out
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
        "      - hello_r6"
    )
    topics <- .rd_topics(dir)

    out <- .reference_index(.reference_sections(dir, topics), topics)

    expect_identical(
        out,
        c(
            "# Reference",
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
    sections <- .reference_sections(dir, topics)

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

    expect_error(.reference_sections(dir, topics), "Unknown key")
})

test_that("an unknown topic in altdoc/reference.yml is an error", {
    dir <- local_reference_package(
        "reference:",
        "  - title: Greetings",
        "    contents:",
        "      - no_such_topic"
    )
    topics <- .rd_topics(dir)
    sections <- .reference_sections(dir, topics)

    expect_error(
        .reference_index(sections, topics),
        "not a known topic name or alias"
    )
})
