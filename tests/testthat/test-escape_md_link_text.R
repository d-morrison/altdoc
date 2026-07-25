test_that(".escape_md_link_text escapes square brackets and backslashes", {
    expect_identical(
        .escape_md_link_text("Do not use R6 [beta]"),
        "Do not use R6 \\[beta\\]"
    )
    expect_identical(
        .escape_md_link_text("A \\ backslash"),
        "A \\\\ backslash"
    )
    expect_identical(
        .escape_md_link_text("Plain title"),
        "Plain title"
    )
})

test_that(".escape_md_link_text escapes the backslash it adds only once", {
    expect_identical(
        .escape_md_link_text("\\["),
        "\\\\\\["
    )
})
