test_that(".rd_title extracts a plain title", {
    rd <- rd_from_text(
        "\\name{foo}",
        "\\alias{foo}",
        "\\title{A plain title}",
        "\\description{d}"
    )
    expect_identical(.rd_title(rd), "A plain title")
})

test_that(".rd_title squishes a title split across lines", {
    rd <- rd_from_text(
        "\\name{foo}",
        "\\alias{foo}",
        "\\title{A title that runs",
        "  across two lines}",
        "\\description{d}"
    )
    expect_identical(.rd_title(rd), "A title that runs across two lines")
})

test_that(".rd_title converts inline markup to Markdown", {
    rd <- rd_from_text(
        "\\name{foo}",
        "\\alias{foo}",
        "\\title{Use \\code{foo()} with \\emph{care} and \\strong{caution}}",
        "\\description{d}"
    )
    expect_identical(
        .rd_title(rd),
        "Use `foo()` with *care* and **caution**"
    )
})

test_that(".rd_title keeps the text of a link but drops the target", {
    rd <- rd_from_text(
        "\\name{foo}",
        "\\alias{foo}",
        "\\title{See \\link[stats]{median}}",
        "\\description{d}"
    )
    expect_identical(.rd_title(rd), "See median")
})

test_that(".rd_title picks the Markdown branch of a conditional", {
    rd <- rd_from_text(
        "\\name{foo}",
        "\\alias{foo}",
        "\\title{\\ifelse{html}{yes}{no} and \\if{latex}{dropped}}",
        "\\description{d}"
    )
    expect_identical(.rd_title(rd), "yes and")
})

test_that(".rd_title returns NA when there is no title", {
    rd <- rd_from_text("\\name{foo}", "\\alias{foo}", "\\description{d}")
    expect_identical(.rd_title(rd), NA_character_)
})

test_that(".rd_code_span widens the fence around embedded backticks", {
    expect_identical(.rd_code_span("foo"), "`foo`")
    expect_identical(.rd_code_span("a `b` c"), "``a `b` c``")
})

test_that(".rd_title keeps only the LaTeX branch of a two-argument \\eqn", {
    rd <- rd_from_text(
        "\\name{foo}",
        "\\alias{foo}",
        "\\title{Compute \\eqn{x^2}{x squared} exactly}",
        "\\description{d}"
    )
    expect_identical(.rd_title(rd), "Compute $x^2$ exactly")
})

test_that(".rd_title renders a one-argument \\eqn as a math span", {
    rd <- rd_from_text(
        "\\name{foo}",
        "\\alias{foo}",
        "\\title{Estimate \\eqn{\\alpha}}",
        "\\description{d}"
    )
    expect_identical(.rd_title(rd), "Estimate $\\alpha$")
})
