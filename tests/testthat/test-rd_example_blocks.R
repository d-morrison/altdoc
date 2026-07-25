local_examples_rd <- function(...) {
    rd_from_text(
        "\\name{f}",
        "\\alias{f}",
        "\\title{T}",
        "\\usage{f(x)}",
        "\\description{d}",
        "\\examples{",
        ...,
        "}"
    )
}

test_that(".rd_example_blocks splits a \\dontrun{} out of the code around it", {
    rd <- local_examples_rd(
        "1 + 1",
        "\\dontrun{",
        "stop('boom')",
        "}",
        "2 + 2"
    )
    blocks <- .rd_example_blocks(rd)

    expect_identical(
        vapply(blocks, function(b) b$eval, logical(1)),
        c(TRUE, FALSE, TRUE)
    )
    expect_match(blocks[[2]]$code, "stop('boom')", fixed = TRUE)
    expect_match(blocks[[1]]$code, "1 + 1", fixed = TRUE)
    expect_match(blocks[[3]]$code, "2 + 2", fixed = TRUE)
})

test_that(".rd_example_blocks treats \\donttest{} the same as \\dontrun{}", {
    rd <- local_examples_rd("1 + 1", "\\donttest{", "Sys.sleep(100)", "}")
    blocks <- .rd_example_blocks(rd)
    expect_identical(
        vapply(blocks, function(b) b$eval, logical(1)),
        c(TRUE, FALSE)
    )
})

test_that(".rd_example_blocks merges adjacent code into one block", {
    # Each line is its own RCODE node, so without merging every line of an
    # ordinary example would become a separate chunk.
    rd <- local_examples_rd("1 + 1", "2 + 2", "3 + 3")
    blocks <- .rd_example_blocks(rd)
    expect_length(blocks, 1)

    # Merging concatenates the nodes' text directly, which is only safe while
    # each node keeps its own trailing newline. Pin the lines rather than the
    # block count, so a change that stripped newlines fails here instead of
    # silently emitting `1 + 12 + 2`.
    expect_identical(
        .split_example_lines(blocks[[1]]$code),
        c("", "1 + 1", "2 + 2", "3 + 3")
    )
})

test_that(".rd_example_blocks does not trip on an example that mentions dontrun", {
    # The old check grepped the rendered page for the string, so a comment
    # naming the tag disabled the whole page.
    rd <- local_examples_rd(
        "# not a \\\\dontrun{} block, just a mention",
        "1 + 1"
    )
    blocks <- .rd_example_blocks(rd)
    expect_length(blocks, 1)
    expect_true(blocks[[1]]$eval)
})

test_that(".rd_example_blocks drops \\dontshow{} and whitespace-only blocks", {
    rd <- local_examples_rd("\\dontshow{setup()}", "1 + 1")
    blocks <- .rd_example_blocks(rd)
    expect_length(blocks, 1)
    expect_false(grepl("setup()", blocks[[1]]$code, fixed = TRUE))
})

test_that(".rd_example_blocks drops \\testonly{} the same way", {
    # Same branch as \dontshow{}, named separately so the symmetric treatment
    # is visible rather than inferred from the shared code path.
    rd <- local_examples_rd("\\testonly{stopifnot(TRUE)}", "1 + 1")
    blocks <- .rd_example_blocks(rd)
    expect_length(blocks, 1)
    expect_false(grepl("stopifnot", blocks[[1]]$code, fixed = TRUE))
    expect_true(blocks[[1]]$eval)
})

test_that(".rd_example_blocks returns nothing for a topic with no examples", {
    rd <- rd_from_text(
        "\\name{f}",
        "\\alias{f}",
        "\\title{T}",
        "\\usage{f(x)}",
        "\\description{d}"
    )
    expect_identical(.rd_example_blocks(rd), list())
})
