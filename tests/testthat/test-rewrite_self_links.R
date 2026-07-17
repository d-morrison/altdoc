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
    expect_false(grepl("https://example.com", man_out, fixed = TRUE))

    ### links not matching a registered prefix are untouched (no DESCRIPTION
    ### here, so only the pkgdown.yml prefixes are active; the per-package
    ### rdrr.io filtering is exercised in the rdrr-fallback test below)
    external_out <- paste(.readlines(external_html), collapse = "\n")
    expect_true(grepl(
        'href="https://rdrr.io/r/base/library.html"',
        external_out,
        fixed = TRUE
    ))
})

test_that(".rewrite_self_links() rewrites rdrr.io fallback self-links", {
    root <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(root, "docs", "vignettes", "articles")))
    fs::dir_create(fs::path_join(c(root, "docs", "man")))

    ### no altdoc/pkgdown.yml: the rdrr.io rewrite must not depend on it
    cat(
        "Package: mypkg\nVersion: 0.0.1\n",
        file = fs::path_join(c(root, "DESCRIPTION"))
    )

    article_html <- fs::path_join(c(
        root,
        "docs/vignettes/articles/simulation.html"
    ))
    cat(
        paste0(
            '<a href="https://rdrr.io/pkg/mypkg/man/simulate_data.html">',
            "simulate_data()</a>\n",
            '<a href="https://rdrr.io/pkg/otherpkg/man/foo.html">foo()</a>\n',
            '<a href="https://rdrr.io/r/base/library.html">library()</a>'
        ),
        file = article_html
    )

    .rewrite_self_links(fs::path_join(c(root, "docs")), root)

    article_out <- paste(.readlines(article_html), collapse = "\n")
    expect_true(grepl(
        'href="../../man/simulate_data.html"',
        article_out,
        fixed = TRUE
    ))
    expect_false(grepl("rdrr.io/pkg/mypkg", article_out, fixed = TRUE))

    ### rdrr.io links to other packages and base R are untouched
    expect_true(grepl(
        'href="https://rdrr.io/pkg/otherpkg/man/foo.html"',
        article_out,
        fixed = TRUE
    ))
    expect_true(grepl(
        'href="https://rdrr.io/r/base/library.html"',
        article_out,
        fixed = TRUE
    ))
})

test_that(".rewrite_self_links() rewrites both URL forms in one pass", {
    root <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(root, "altdoc")))
    fs::dir_create(fs::path_join(c(root, "docs", "man")))

    cat(
        "Package: mypkg\nVersion: 0.0.1\n",
        file = fs::path_join(c(root, "DESCRIPTION"))
    )
    cat(
        "urls:\n  reference: https://example.com/pkg/man\n",
        file = fs::path_join(c(root, "altdoc", "pkgdown.yml"))
    )

    man_html <- fs::path_join(c(root, "docs/man/simulate_data.html"))
    cat(
        paste0(
            '<a href="https://example.com/pkg/man/prep_analysis_data.html">',
            "prep_analysis_data()</a>\n",
            '<a href="https://rdrr.io/pkg/mypkg/man/screening_sens.html">',
            "screening_sens()</a>\n",
            '<a href="https://rdrr.io/pkg/otherpkg/man/foo.html">foo()</a>'
        ),
        file = man_html
    )

    .rewrite_self_links(fs::path_join(c(root, "docs")), root)

    man_out <- paste(.readlines(man_html), collapse = "\n")
    expect_true(grepl(
        'href="../man/prep_analysis_data.html"',
        man_out,
        fixed = TRUE
    ))
    expect_true(grepl(
        'href="../man/screening_sens.html"',
        man_out,
        fixed = TRUE
    ))
    expect_false(grepl("https://example.com", man_out, fixed = TRUE))
    expect_false(grepl("rdrr.io/pkg/mypkg", man_out, fixed = TRUE))

    ### rdrr.io links to other packages stay untouched even with both
    ### prefix types active
    expect_true(grepl(
        'href="https://rdrr.io/pkg/otherpkg/man/foo.html"',
        man_out,
        fixed = TRUE
    ))
})

test_that(".rewrite_self_links() is a no-op without pkgdown.yml or DESCRIPTION", {
    root <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(root, "docs")))
    html_file <- fs::path_join(c(root, "docs/index.html"))
    original <- '<a href="https://rdrr.io/r/base/library.html">library()</a>'
    cat(original, file = html_file)

    expect_no_error(.rewrite_self_links(fs::path_join(c(root, "docs")), root))
    expect_identical(paste(.readlines(html_file), collapse = "\n"), original)
})

test_that(".rewrite_self_links() is a no-op when pkgdown.yml has no urls and there is no DESCRIPTION", {
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
