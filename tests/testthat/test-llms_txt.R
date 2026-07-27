test_that(".llms_txt builds the llmstxt.org shape", {
    topics <- data.frame(
        name = c("as_pop_data", "altdoc_options"),
        title = c("Load a survey data set", "Package options"),
        internal = c(FALSE, FALSE),
        is_fun = c(TRUE, FALSE),
        stringsAsFactors = FALSE
    )

    out <- .llms_txt(
        pkg_name = "mypkg",
        pkg_title = "Do Useful Things",
        topics = topics,
        base = "https://example.org/mypkg",
        ext = "html"
    )

    expect_equal(out[1], "# mypkg")
    expect_true(any(out == "> Do Useful Things"))
    expect_true(any(out == "## Reference"))
    expect_true(any(out == paste0(
        "- [as_pop_data()](https://example.org/mypkg/man/as_pop_data.html)",
        ": Load a survey data set"
    )))
    # Only topics documenting something callable get the `()` suffix.
    expect_true(any(grepl(
        "- [altdoc_options](https://example.org/mypkg/man/altdoc_options.html)",
        out,
        fixed = TRUE
    )))
})

test_that(".llms_txt omits internal topics", {
    topics <- data.frame(
        name = c("public_fn", "dot_helper"),
        title = c("A public function", "An internal helper"),
        internal = c(FALSE, TRUE),
        is_fun = c(TRUE, TRUE),
        stringsAsFactors = FALSE
    )

    out <- .llms_txt("mypkg", topics = topics, base = "https://example.org")

    expect_true(any(grepl("public_fn", out, fixed = TRUE)))
    expect_false(any(grepl("dot_helper", out, fixed = TRUE)))
})

test_that(".llms_txt falls back to relative links without a base URL", {
    topics <- data.frame(
        name = "as_pop_data",
        title = "Load a survey data set",
        internal = FALSE,
        is_fun = TRUE,
        stringsAsFactors = FALSE
    )

    out <- .llms_txt("mypkg", topics = topics, base = NULL, ext = "md")

    expect_true(any(grepl(
        "- [as_pop_data()](man/as_pop_data.md): Load a survey data set",
        out,
        fixed = TRUE
    )))
})

test_that(".llms_txt lists vignettes under Articles", {
    vignettes <- data.frame(
        name = c("get-started", "customize"),
        title = c("Get started", "Customize the site"),
        stringsAsFactors = FALSE
    )

    out <- .llms_txt(
        "mypkg",
        vignettes = vignettes,
        base = "https://example.org",
        ext = "html"
    )

    expect_true(any(out == "## Articles"))
    expect_true(any(out == "- [Get started](https://example.org/vignettes/get-started.html)"))
    # No `\title{}` equivalent for a vignette, so no trailing description.
    expect_false(any(grepl("Get started](.*): ", out)))
})

test_that(".llms_txt drops a description identical to its label", {
    topics <- data.frame(
        name = "as_pop_data",
        title = "as_pop_data",
        internal = FALSE,
        is_fun = FALSE,
        stringsAsFactors = FALSE
    )

    out <- .llms_txt("mypkg", topics = topics, base = NULL, ext = "md")

    expect_true(any(out == "- [as_pop_data](man/as_pop_data.md)"))
})

test_that(".llms_txt_ext serves Markdown only where the generator does", {
    # docsify/docute fetch the Markdown at runtime, so it is on the site;
    # mkdocs and quarto_website compile it away.
    expect_equal(.llms_txt_ext("docsify"), "md")
    expect_equal(.llms_txt_ext("docute"), "md")
    expect_equal(.llms_txt_ext("mkdocs"), "html")
    expect_equal(.llms_txt_ext("quarto_website"), "html")
})

test_that(".site_url prefers pkgdown.yml, then DESCRIPTION, then nothing", {
    create_local_package()

    # No URL anywhere.
    expect_null(.site_url("."))

    desc::desc_set_urls("https://example.org/mypkg/")
    # The trailing slash is stripped so links do not end up doubled.
    expect_equal(.site_url("."), "https://example.org/mypkg")

    # altdoc/pkgdown.yml wins, since it is where a maintainer records a site
    # served from somewhere other than the first DESCRIPTION URL.
    fs::dir_create("altdoc")
    writeLines(
        c("urls:", "  reference: https://docs.example.org/pkg/man"),
        "altdoc/pkgdown.yml"
    )
    expect_equal(.site_url("."), "https://docs.example.org/pkg")
})

test_that(".import_llms_txt honors the reference.yml opt-out", {
    create_local_package()
    setup_docs("docute")
    fs::dir_create("docs")

    fs::dir_create("altdoc")
    writeLines("llms_txt: false", "altdoc/reference.yml")

    .import_llms_txt(src_dir = ".", tar_dir = "docs", tool = "docute")
    expect_false(fs::file_exists("docs/llms.txt"))
})
