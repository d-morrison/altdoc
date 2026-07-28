test_that(".substitute_altdoc_vars removes github if no url", {
    skip_if(!.quarto_is_installed())
    create_local_package()
    desc::desc_set_urls("https://foobar.com")
    setup_docs("docute")
    render_docs()
    content <- .readlines("docs/index.html")
    expect_false(
        any(grepl("$ALTDOC_PACKAGE_URL_GITHUB", content, fixed = TRUE))
    )
})

test_that(".substitute_altdoc_vars removes website if no url", {
    skip_if(!.quarto_is_installed())
    create_local_package()
    desc::desc_set_urls("https://github.com/foo/bar")
    setup_docs("docute")
    render_docs()
    content <- .readlines("docs/index.html")
    expect_false(any(grepl("$ALTDOC_PACKAGE_URL", content, fixed = TRUE)))
})

test_that(".substitute_altdoc_vars keeps a non-GitHub forge URL as the website", {
    # The counterpart to the test above, and the reason its filter checks
    # `github.com` rather than `.is_forge_url()`. The GitHub URL is dropped
    # because `$ALTDOC_PACKAGE_URL_GITHUB` renders it elsewhere on the same
    # page; a GitLab URL has no such second home, since `.gh_url()` only
    # recognizes GitHub, so dropping it would leave the page with no link to
    # the project at all. Pinned here so the asymmetry reads as a decision
    # rather than an oversight (#81).
    skip_if(!.quarto_is_installed())
    create_local_package()
    desc::desc_set_urls("https://gitlab.com/foo/bar")
    setup_docs("docute")
    render_docs()
    content <- .readlines("docs/index.html")
    expect_true(any(grepl("https://gitlab.com/foo/bar", content, fixed = TRUE)))
    expect_false(any(grepl("$ALTDOC_PACKAGE_URL", content, fixed = TRUE)))
})
