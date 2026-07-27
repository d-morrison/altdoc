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
    expect_true(any(
        out ==
            paste0(
                "- [as_pop_data()]",
                "(https://example.org/mypkg/man/as_pop_data.html)",
                ": Load a survey data set"
            )
    ))
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
    expect_true(any(
        out == "- [Get started](https://example.org/vignettes/get-started.html)"
    ))
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

test_that(".llms_txt_ext matches what each generator publishes", {
    # Markdown survives into the published tree for all three of these:
    # docsify/docute fetch it at runtime, and mkdocs builds HTML alongside the
    # .md sources rather than replacing them. Same split as
    # `.import_reference()`.
    expect_equal(.llms_txt_ext("docsify"), "md")
    expect_equal(.llms_txt_ext("docute"), "md")
    # Not "html": mkdocs leaves use_directory_urls at its TRUE default, so it
    # serves /man/foo/, never /man/foo.html -- an extension-based HTML link is
    # wrong for it twice over.
    expect_equal(.llms_txt_ext("mkdocs"), "md")
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

    # A host-only reference URL has no path segment to strip, so there is no
    # site root to recover; fall through rather than return the bare scheme.
    writeLines(
        c("urls:", "  reference: https://docs.example.org"),
        "altdoc/pkgdown.yml"
    )
    expect_equal(.site_url("."), "https://example.org/mypkg")
})

test_that(".site_url refuses a forge URL", {
    create_local_package()

    # A package whose only URL is its repository has no site. Using the repo
    # as the base would emit links like <repo>/man/foo.md, which do not exist.
    desc::desc_set_urls("https://github.com/user/pkg")
    expect_null(.site_url("."))

    # The same applies to a forge URL reached through pkgdown.yml.
    fs::dir_create("altdoc")
    writeLines(
        c("urls:", "  reference: https://gitlab.com/user/pkg/man"),
        "altdoc/pkgdown.yml"
    )
    expect_null(.site_url("."))

    # A real site alongside the repo URL is still used.
    desc::desc_set_urls(c(
        "https://github.com/user/pkg",
        "https://user.github.io/pkg"
    ))
    fs::file_delete("altdoc/pkgdown.yml")
    expect_equal(.site_url("."), "https://user.github.io/pkg")
})

test_that(".import_llms_txt honors the reference.yml opt-out", {
    create_local_package()
    setup_docs("docute")
    fs::dir_create("docs")

    # The fixture needs a real .Rd, or the emptiness guard suppresses the file
    # on its own and the assertion below holds whether or not the opt-out is
    # honored -- it would pass with the `llms_txt: false` branch deleted.
    fs::dir_create("man")
    writeLines(
        c(
            "\\name{hello}",
            "\\alias{hello}",
            "\\title{Say hello to someone}",
            "\\usage{hello(who)}",
            "\\description{Says hello.}"
        ),
        "man/hello.Rd"
    )

    # Confirm the fixture would otherwise produce a file, so the opt-out is
    # what this test actually measures.
    .import_llms_txt(src_dir = ".", tar_dir = "docs", tool = "docute")
    expect_true(fs::file_exists("docs/llms.txt"))
    fs::file_delete("docs/llms.txt")

    fs::dir_create("altdoc")
    writeLines("llms_txt: false", "altdoc/reference.yml")

    .import_llms_txt(src_dir = ".", tar_dir = "docs", tool = "docute")
    expect_false(fs::file_exists("docs/llms.txt"))
})

test_that(".import_llms_txt removes a previously published file on opt-out", {
    create_local_package()
    setup_docs("docute")
    fs::dir_create("docs")

    fs::dir_create("man")
    writeLines(
        c(
            "\\name{hello}",
            "\\alias{hello}",
            "\\title{Say hello to someone}",
            "\\usage{hello(who)}",
            "\\description{Says hello.}"
        ),
        "man/hello.Rd"
    )

    .import_llms_txt(src_dir = ".", tar_dir = "docs", tool = "docute")
    expect_true(fs::file_exists("docs/llms.txt"))

    # `render_docs()` clears its render target only for quarto_website, where
    # it is the throwaway `_quarto/`. For this generator the target is `docs/`,
    # which persists between renders -- so opting out has to delete the file,
    # not merely decline to rewrite it. Otherwise the site serves the old index
    # forever, and it goes stale as topics change.
    fs::dir_create("altdoc")
    writeLines("llms_txt: false", "altdoc/reference.yml")

    .import_llms_txt(src_dir = ".", tar_dir = "docs", tool = "docute")
    expect_false(fs::file_exists("docs/llms.txt"))
})

test_that(".import_llms_txt removes the file when nothing is left to list", {
    create_local_package()
    setup_docs("docute")
    fs::dir_create("docs")
    fs::dir_create("man")

    writeLines(
        c(
            "\\name{hello}",
            "\\alias{hello}",
            "\\title{Say hello to someone}",
            "\\usage{hello(who)}",
            "\\description{Says hello.}"
        ),
        "man/hello.Rd"
    )
    .import_llms_txt(src_dir = ".", tar_dir = "docs", tool = "docute")
    expect_true(fs::file_exists("docs/llms.txt"))

    # The same staleness applies without any opt-out: a package whose topics
    # all become internal has nothing to index, and the old file would
    # otherwise keep being served.
    fs::file_delete("man/hello.Rd")
    .import_llms_txt(src_dir = ".", tar_dir = "docs", tool = "docute")
    expect_false(fs::file_exists("docs/llms.txt"))
})

test_that(".reference_settings rejects a non-logical llms_txt", {
    create_local_package()
    fs::dir_create("altdoc")

    # Quoted, so YAML reads it as the string "false" -- which `isFALSE()` does
    # not match, so it would silently generate the file the author asked to
    # skip.
    writeLines('llms_txt: "false"', "altdoc/reference.yml")
    expect_error(.reference_settings("."), "Invalid")

    writeLines("llms_txt: 0", "altdoc/reference.yml")
    expect_error(.reference_settings("."), "Invalid")

    # The real thing still works, and so does leaving the key out.
    writeLines("llms_txt: false", "altdoc/reference.yml")
    expect_false(.reference_settings(".")$llms_txt)
})

test_that(".import_llms_txt writes nothing when every topic is internal", {
    create_local_package()
    setup_docs("docute")
    fs::dir_create("docs")

    # Gating on the unfiltered topic count would pass this guard and write a
    # file carrying the H1 and title with no `## Reference` section --- an
    # index of nothing.
    fs::dir_create("man")
    writeLines(
        c(
            "\\name{dot_helper}",
            "\\alias{dot_helper}",
            "\\title{An internal helper}",
            "\\usage{dot_helper()}",
            "\\description{Internal.}",
            "\\keyword{internal}"
        ),
        "man/dot_helper.Rd"
    )

    .import_llms_txt(src_dir = ".", tar_dir = "docs", tool = "docute")
    expect_false(fs::file_exists("docs/llms.txt"))
})

test_that(".import_llms_txt writes a file listing the package's topics", {
    create_local_package()
    setup_docs("docute")
    fs::dir_create("docs")
    desc::desc_set_urls("https://example.org/mypkg")

    # A package with no documented topics and no vignettes has nothing to
    # index, and `.import_llms_txt()` correctly writes nothing -- so the
    # fixture needs a real .Rd for this to exercise the write path at all.
    fs::dir_create("man")
    writeLines(
        c(
            "\\name{hello}",
            "\\alias{hello}",
            "\\title{Say hello to someone}",
            "\\usage{hello(who)}",
            "\\description{Says hello.}"
        ),
        "man/hello.Rd"
    )

    .import_llms_txt(src_dir = ".", tar_dir = "docs", tool = "docute")

    expect_true(fs::file_exists("docs/llms.txt"))
    content <- .readlines("docs/llms.txt")
    expect_true(any(grepl("^# ", content)))
    expect_true(any(content == "## Reference"))
    # The summary is the .Rd \title{}, so it cannot drift from the help page.
    expect_true(any(grepl("Say hello to someone", content, fixed = TRUE)))
    # docute serves the Markdown, so entries point at it, not at .html.
    expect_true(any(grepl("man/hello.md", content, fixed = TRUE)))
    expect_false(any(grepl(".html)", content, fixed = TRUE)))
})

test_that(".llms_txt_vignettes does not double-list a rendered .qmd", {
    create_local_package()
    fs::dir_create("docs/vignettes", recurse = TRUE)

    # What `.render_one_vignette()` actually leaves behind for docsify/docute/
    # mkdocs: it copies the source in, renders a sibling .md, and -- unlike
    # `.import_man()` -- never deletes the copy. This repo's own
    # vignettes/customize.qmd produces exactly this pair.
    writeLines("# Customize the site", "docs/vignettes/customize.qmd")
    writeLines("# Customize the site", "docs/vignettes/customize.md")

    out <- .llms_txt_vignettes(".", "docs", "docsify")

    expect_equal(nrow(out), 1)
    expect_equal(out$name, "customize")
    # The rendered page, not the leftover source.
    expect_equal(out$ext, "md")
})

test_that(".llms_txt_vignettes includes .Rmd under quarto_website", {
    create_local_package()
    fs::dir_create("_quarto/vignettes", recurse = TRUE)

    # quarto_website copies vignettes/ verbatim, so the sources are what is
    # there and Quarto renders both. The sidebar builder matches .Rmd too.
    writeLines("# Get started", "_quarto/vignettes/get-started.Rmd")
    writeLines("# Customize", "_quarto/vignettes/customize.qmd")

    out <- .llms_txt_vignettes(".", "_quarto", "quarto_website")

    expect_setequal(out$name, c("get-started", "customize"))
    # Both are rendered by Quarto, so both are published as HTML.
    expect_equal(unique(out$ext), "html")
})

test_that(".llms_txt_vignettes finds nested quarto_website articles", {
    create_local_package()
    fs::dir_create("_quarto/vignettes/articles", recurse = TRUE)

    # quarto_website gets `vignettes/` copied whole, subdirectories included,
    # and Quarto renders a nested article -- the usual pkgdown `articles/`
    # layout. The sidebar globs recursively and lists it, so an index that
    # does not would omit a page the site itself links.
    writeLines("# Get started", "_quarto/vignettes/start.qmd")
    writeLines("# Deep dive", "_quarto/vignettes/articles/deep-dive.qmd")

    out <- .llms_txt_vignettes(".", "_quarto", "quarto_website")

    # The name carries the subdirectory, because it becomes the link's path:
    # the page is served at vignettes/articles/deep-dive.html.
    expect_setequal(out$name, c("start", "articles/deep-dive"))
    # The label stays readable -- a reader wants the article, not the path.
    expect_equal(out$title[out$name == "articles/deep-dive"], "deep-dive")
})

test_that(".llms_txt_vignettes does not recurse for the other generators", {
    create_local_package()
    fs::dir_create("docs/vignettes/nested", recurse = TRUE)

    # These generators render vignettes non-recursively and their sidebars
    # glob non-recursively to match, so nothing of theirs lives in a
    # subdirectory. Recursing here would index a page the site never built.
    writeLines("# Top", "docs/vignettes/top.md")
    writeLines("# Buried", "docs/vignettes/nested/buried.md")

    out <- .llms_txt_vignettes(".", "docs", "docsify")

    expect_equal(out$name, "top")
})

test_that(".llms_txt_vignettes keeps a .pdf vignette at its own extension", {
    create_local_package()
    fs::dir_create("_quarto/vignettes", recurse = TRUE)

    writeLines("# Guide", "_quarto/vignettes/guide.qmd")
    writeLines("%PDF-1.4", "_quarto/vignettes/manual.pdf")

    out <- .llms_txt_vignettes(".", "_quarto", "quarto_website")

    # A .pdf is copied, not rendered, so it does not become .html with the
    # rest -- and it is listed rather than silently dropped.
    expect_equal(out$ext[out$name == "manual"], "pdf")
    expect_equal(out$ext[out$name == "guide"], "html")

    # The label must not carry the file extension. `.get_vignettes_titles()`
    # strips only a `.md` suffix when it finds no title, so it hands back
    # `manual.pdf` verbatim -- which would both read wrong and disagree with
    # the quarto_website sidebar, which strips `.pdf` itself.
    expect_equal(out$title[out$name == "manual"], "manual")
    expect_equal(out$title[out$name == "guide"], "guide")

    # Names come from the file list, so they must not ride along as row names.
    expect_null(attr(out$title, "names"))
})

test_that(".llms_txt escapes brackets in link labels", {
    # A `[` closes the label early, leaving the rest as literal text beside a
    # broken link. The docsify sidebar escapes its own labels for this reason;
    # these rows are built from the same kind of untrusted title.
    vignettes <- data.frame(
        name = "r6",
        title = "Do not use R6 [beta]",
        ext = "md",
        stringsAsFactors = FALSE
    )

    out <- .llms_txt("mypkg", vignettes = vignettes, base = NULL)

    expect_true(any(
        out == "- [Do not use R6 \\[beta\\]](vignettes/r6.md)"
    ))
})

test_that(".llms_txt escapes brackets in a topic name", {
    # Extraction operators are documented topics too, and `[.foo` breaks the
    # same way a bracketed vignette title does.
    topics <- data.frame(
        name = "[.myclass",
        title = "Subset a myclass object",
        internal = FALSE,
        is_fun = TRUE,
        stringsAsFactors = FALSE
    )

    out <- .llms_txt("mypkg", topics = topics, base = NULL, ext = "md")

    expect_true(any(grepl("- [\\[.myclass()](", out, fixed = TRUE)))
})

test_that(".llms_txt uses each article's own extension", {
    vignettes <- data.frame(
        name = c("guide", "manual"),
        title = c("Guide", "Manual"),
        ext = c("html", "pdf"),
        stringsAsFactors = FALSE
    )

    out <- .llms_txt("mypkg", vignettes = vignettes, base = "https://e.org")

    expect_true(any(out == "- [Guide](https://e.org/vignettes/guide.html)"))
    expect_true(any(out == "- [Manual](https://e.org/vignettes/manual.pdf)"))
})
