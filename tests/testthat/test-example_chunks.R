load_line <- "library(\"testpkg\")"

chunk_headers <- function(x) {
    grep("^```\\{r", x, value = TRUE)
}

test_that(".example_chunks emits one chunk per block, carrying its eval flag", {
    blocks <- list(
        list(code = "1 + 1\n", eval = TRUE),
        list(code = "stop('boom')\n", eval = FALSE),
        list(code = "2 + 2\n", eval = TRUE)
    )
    out <- .example_chunks(blocks, pkg_load = load_line)

    expect_identical(
        chunk_headers(out),
        c(
            "```{r, warning=FALSE, message=FALSE, eval=TRUE}",
            "```{r, warning=FALSE, message=FALSE, eval=FALSE}",
            "```{r, warning=FALSE, message=FALSE, eval=TRUE}"
        )
    )
})

test_that(".example_chunks loads the package in the first evaluated block", {
    # Not simply the first block: a leading \dontrun{} block never runs, so
    # putting the `library()` call there would print it in a block that cannot
    # use it while the evaluated block below went without.
    blocks <- list(
        list(code = "stop('boom')\n", eval = FALSE),
        list(code = "1 + 1\n", eval = TRUE)
    )
    out <- .example_chunks(blocks, pkg_load = load_line)

    expect_length(grep(load_line, out, fixed = TRUE), 1)
    expect_identical(
        out[grep(load_line, out, fixed = TRUE) - 1],
        "```{r, warning=FALSE, message=FALSE, eval=TRUE}"
    )
})

test_that(".example_chunks still loads the package when nothing evaluates", {
    # A false @examplesIf condition disables every block. The page then reads
    # as it always has, with the library call at the top.
    blocks <- list(list(code = "1 + 1\n", eval = FALSE))
    out <- .example_chunks(blocks, pkg_load = load_line)

    expect_identical(out[2], load_line)
})

test_that(".example_chunks returns nothing when there are no blocks", {
    expect_identical(
        .example_chunks(list(), pkg_load = load_line),
        character(0)
    )
})

test_that(".example_chunks keeps the blank lines inside a block", {
    # Trimming them would silently reflow every page that already renders.
    blocks <- list(list(code = "\n1 + 1\n\n2 + 2\n", eval = TRUE))
    out <- .example_chunks(blocks, pkg_load = load_line)

    expect_identical(
        out,
        c(
            "```{r, warning=FALSE, message=FALSE, eval=TRUE}",
            load_line,
            "",
            "1 + 1",
            "",
            "2 + 2",
            "```"
        )
    )
})
