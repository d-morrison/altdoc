test_that(".escape_js_single_quoted escapes apostrophes and backslashes", {
    expect_identical(
        .escape_js_single_quoted("Don't use R6"),
        "Don\\'t use R6"
    )
    expect_identical(
        .escape_js_single_quoted("A \\ backslash"),
        "A \\\\ backslash"
    )
    expect_identical(
        .escape_js_single_quoted("Plain title"),
        "Plain title"
    )
})

test_that(".escape_js_single_quoted escapes the backslash it adds only once", {
    # A backslash already in the text is doubled, and the one introduced in
    # front of the apostrophe is not --- so the reader of the literal sees the
    # original backslash followed by a real apostrophe.
    expect_identical(
        .escape_js_single_quoted("\\'"),
        "\\\\\\'"
    )
})
