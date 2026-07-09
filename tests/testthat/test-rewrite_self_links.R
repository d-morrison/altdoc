test_that(".rewrite_self_links() rewrites absolute self-links as relative", {
    root <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(root, "altdoc")))
    fs::dir_create(fs::path_join(c(root, "docs", "vignettes", "articles")))
    fs::dir_create(fs::path_join(c(root, "docs", "man")))

    cat(
        "urls:\n  reference: https://example.com/pkg/man\n  article: https://example.com/pkg/vignettes\n",
        file = fs::path_join(c(root, "altdoc", "pkgdown.yml"))
    )

    article_html <- fs::path_join(c(
        root,
        "docs/vignettes/articles/simulation.html"
    ))
    cat(
        '<a href="https://example.com/pkg/man/simulate_data.html">simulate_data()</a>',
        file = article_html
    )

    man_html <- fs::path_join(c(root, "docs/man/simulate_data.html"))
    cat(
        '<a href="https://example.com/pkg/man/prep_analysis_data.html">prep_analysis_data()</a>',
        file = man_html
    )

    external_html <- fs::path_join(c(root, "docs/index.html"))
    cat(
        '<a href="https://rdrr.io/r/base/library.html">library()</a>',
        file = external_html
    )

    .rewrite_self_links(fs::path_join(c(root, "docs")), root)

    article_out <- paste(.readlines(article_html), collapse = "\n")
    expect_true(grepl(
        'href="../../man/simulate_data.html"',
        article_out,
        fixed = TRUE
    ))
    expect_false(grepl("https://example.com", article_out, fixed = TRUE))

    man_out <- paste(.readlines(man_html), collapse = "\n")
    expect_true(grepl(
        'href="../man/prep_analysis_data.html"',
        man_out,
        fixed = TRUE
    ))

    ### links to other packages are untouched
    external_out <- paste(.readlines(external_html), collapse = "\n")
    expect_true(grepl(
        'href="https://rdrr.io/r/base/library.html"',
        external_out,
        fixed = TRUE
    ))
})

test_that(".rewrite_self_links() is a no-op without altdoc/pkgdown.yml", {
    root <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(root, "docs")))
    html_file <- fs::path_join(c(root, "docs/index.html"))
    original <- '<a href="https://rdrr.io/r/base/library.html">library()</a>'
    cat(original, file = html_file)

    expect_no_error(.rewrite_self_links(fs::path_join(c(root, "docs")), root))
    expect_identical(paste(.readlines(html_file), collapse = "\n"), original)
})

test_that(".rewrite_self_links() is a no-op when pkgdown.yml has no urls", {
    root <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(root, "altdoc")))
    fs::dir_create(fs::path_join(c(root, "docs")))
    cat(
        "altdoc: 0.0.0\n",
        file = fs::path_join(c(root, "altdoc", "pkgdown.yml"))
    )

    html_file <- fs::path_join(c(root, "docs/index.html"))
    original <- '<a href="https://example.com/pkg/man/foo.html">foo()</a>'
    cat(original, file = html_file)

    expect_no_error(.rewrite_self_links(fs::path_join(c(root, "docs")), root))
    expect_identical(paste(.readlines(html_file), collapse = "\n"), original)
})
