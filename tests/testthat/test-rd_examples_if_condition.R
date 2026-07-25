# The wrapper roxygen2 generates for `@examplesIf`, reproduced verbatim.
examples_if_open <- function(condition) {
    sprintf(
        '\\dontshow{if (%s) (if (getRversion() >= "3.4") withAutoprint else force)(\\{ # examplesIf}',
        condition
    )
}

test_that(".rd_examples_if_condition reads the condition back", {
    rd <- rd_from_text(
        "\\name{f}",
        "\\alias{f}",
        "\\title{T}",
        "\\usage{f(x)}",
        "\\description{d}",
        "\\examples{",
        examples_if_open("2 + 2 == 4"),
        "f()",
        "\\dontshow{\\}) # examplesIf}",
        "}"
    )
    expect_identical(.rd_examples_if_condition(rd), "2 + 2 == 4")
})

test_that(".rd_examples_if_condition keeps a condition's own parentheses", {
    # `requireNamespace()` is the common `@examplesIf` condition in the wild,
    # and it puts a `)` of its own right before the wrapper's. The trailing
    # match is anchored to the wrapper's literal text, so it lands on the outer
    # paren and the condition survives whole.
    for (condition in c(
        "requireNamespace(\"pkg\", quietly = TRUE)",
        "interactive() && requireNamespace(\"pkg\")",
        "(1 + 1) == 2"
    )) {
        rd <- rd_from_text(
            "\\name{f}",
            "\\alias{f}",
            "\\title{T}",
            "\\usage{f(x)}",
            "\\description{d}",
            "\\examples{",
            examples_if_open(condition),
            "f()",
            "\\dontshow{\\}) # examplesIf}",
            "}"
        )
        expect_identical(.rd_examples_if_condition(rd), condition)
    }
})

test_that(".rd_examples_if_condition returns NULL for an ordinary topic", {
    rd <- rd_from_text(
        "\\name{f}",
        "\\alias{f}",
        "\\title{T}",
        "\\usage{f(x)}",
        "\\description{d}",
        "\\examples{",
        "1 + 1",
        "}"
    )
    expect_null(.rd_examples_if_condition(rd))
})

test_that(".rd_examples_if_condition ignores the closing half of the wrapper", {
    # Both halves carry the `# examplesIf` marker, but only the opening one
    # holds a condition --- matching the wrong one would yield nonsense.
    rd <- rd_from_text(
        "\\name{f}",
        "\\alias{f}",
        "\\title{T}",
        "\\usage{f(x)}",
        "\\description{d}",
        "\\examples{",
        "\\dontshow{\\}) # examplesIf}",
        "}"
    )
    expect_null(.rd_examples_if_condition(rd))
})

test_that(".rd_examples_if_condition reads the real fixture topics", {
    dir <- test_path("examples/testpkg.altdoc/man")
    expect_identical(
        .rd_examples_if_condition(
            tools::parse_Rd(fs::path_join(c(dir, "examplesIf_true.Rd")))
        ),
        "2 + 2 == 4"
    )
    expect_identical(
        .rd_examples_if_condition(
            tools::parse_Rd(fs::path_join(c(dir, "examplesIf_false.Rd")))
        ),
        "2 + 2 == 5"
    )
})
