test_that(".setup_github_actions cannot overwrite", {
    create_local_package()
    setup_docs("docute")
    fs::dir_create(".github/workflows")
    fs::file_create(".github/workflows/altdoc.yaml")
    expect_error(
        setup_github_actions(),
        "already exists"
    )
})

test_that(".setup_github_actions works if not mkdocs", {
    create_local_package()
    setup_docs("docute")
    setup_github_actions()
    expect_true(fs::file_exists(".github/workflows/altdoc.yaml"))
    content <- .readlines(".github/workflows/altdoc.yaml")
    expect_false(any(grepl("$ALTDOC_MKDOCS_START", content, fixed = TRUE)))
    expect_false(any(grepl("install mkdocs", content, fixed = TRUE)))
    expect_false(any(grepl(
        "$ALTDOC_MULTIVERSION_START",
        content,
        fixed = TRUE
    )))
    expect_false(any(grepl("r-pkgdown-multiversion", content, fixed = TRUE)))
})

test_that(".setup_github_actions works if mkdocs", {
    skip_if_not(.venv_exists())
    create_local_package()
    setup_docs("mkdocs")
    setup_github_actions()
    expect_true(fs::file_exists(".github/workflows/altdoc.yaml"))
    content <- .readlines(".github/workflows/altdoc.yaml")
    expect_false(any(grepl("$ALTDOC_MKDOCS_START", content, fixed = TRUE)))
    expect_true(any(grepl("install mkdocs", content, fixed = TRUE)))
})

test_that(".setup_github_actions supports multiversion workflow", {
    create_local_package()
    setup_docs("docute")
    setup_github_actions(
        multiversion = TRUE,
        default_landing_page = "latest-tag",
        refs_order = "main latest-tag",
        branches_or_tags_to_list = "^main$|^latest-tag$|^v[0-9]+\\.[0-9]+\\.[0-9]+$"
    )
    content <- .readlines(".github/workflows/altdoc.yaml")

    expect_false(any(grepl(
        "$ALTDOC_MULTIVERSION_START",
        content,
        fixed = TRUE
    )))
    expect_true(any(grepl(
        "target-folder: \\$\\{\\{ env.ALTDOC_DOCS_REF \\}\\}",
        content
    )))
    expect_true(any(grepl(
        "uses: insightsengineering/r-pkgdown-multiversion@v3",
        content,
        fixed = TRUE
    )))
    expect_true(any(grepl(
        'default-landing-page: "latest-tag"',
        content,
        fixed = TRUE
    )))
    expect_true(any(grepl(
        'refs-order: "main latest-tag"',
        content,
        fixed = TRUE
    )))
    expect_true(any(grepl(
        "branches-or-tags-to-list: '^main$|^latest-tag$|^v[0-9]+\\.[0-9]+\\.[0-9]+$'",
        content,
        fixed = TRUE
    )))
})
