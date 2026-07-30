# The files a generator is expected to publish, derived from the source tree of
# the package the test has already moved into rather than listed by hand --- so
# adding an .Rd file or a vignette to a fixture extends the assertion with it,
# instead of leaving a new page nothing checks for.
#
# The extension split is `.import_reference()`'s and `.llms_txt_ext()`'s:
# quarto_website compiles the Markdown away, and the other three leave it in the
# published tree. A `.pdf` vignette is copied rather than rendered, so it keeps
# its own extension under all four. Recursion follows `.import_vignettes()`:
# quarto_website gets `vignettes/` copied whole and Quarto renders the nested
# tree, while docsify and mkdocs discover it recursively themselves, so all
# three publish a nested `vignettes/articles/*`. docute does not.
published_docs_files <- function(tool) {
    ext <- if (identical(tool, "quarto_website")) "html" else "md"

    topics <- fs::path_ext_remove(list.files("man", pattern = "\\.Rd$"))

    # `fs::dir_ls()` errors on a missing directory where `list.files()` above
    # returns nothing, and three fixtures in this file ship no `vignettes/` at
    # all. Guarding keeps a future caller on one of those to a legible testthat
    # failure instead of `[ENOENT] Failed to search directory 'vignettes'`.
    vignettes <- if (fs::dir_exists("vignettes")) {
        fs::path_rel(
            fs::dir_ls(
                "vignettes",
                type = "file",
                # Every generator but docute publishes a nested article; see
                # above.
                recurse = !identical(tool, "docute")
            ),
            "vignettes"
        )
    } else {
        character(0)
    }

    # Only the extensions the generators actually render, mirroring
    # `.import_vignettes()`'s own `src_files` pattern. An unfiltered listing
    # would take a resource file --- an image, a `.bib`, a `.css` --- and expect
    # it published as `<name>.md`, which is a page no generator ever writes.
    vignettes <- vignettes[grepl("\\.(Rmd|qmd|md|pdf)$", vignettes)]

    # A `.pdf` is copied rather than rendered, so it alone keeps its own
    # extension. It is in the set for every generator, `docute` included, even
    # though `docute`'s `src_files` pattern excludes `.pdf`: that pattern only
    # decides what gets *rendered*, and `.import_vignettes()` `dir_copy()`s the
    # whole `vignettes/` directory into the target beforehand. Do not "fix"
    # this to match `src_files` --- the published tree, not that pattern, is
    # what this function is describing.
    vignettes <- ifelse(
        tolower(fs::path_ext(vignettes)) == "pdf",
        vignettes,
        paste0(fs::path_ext_remove(vignettes), ".", ext)
    )

    # The two `length()` guards are load-bearing, not defensive: `paste0()`
    # treats a zero-length argument as `""` rather than propagating the zero
    # length, so `paste0("docs/vignettes/", character(0))` is the bare string
    # `"docs/vignettes/"` --- a directory expected as though it were a page.
    # `c()` drops the NULLs, the same way it drops the docsify branch below.
    c(
        "docs/index.html",
        paste0("docs/reference.", ext),
        if (length(topics) > 0) paste0("docs/man/", topics, ".", ext),
        if (length(vignettes) > 0) paste0("docs/vignettes/", vignettes),
        "docs/llms.txt",
        # docsify is the only generator whose nav is a published file rather
        # than markup inside its landing page.
        if (identical(tool, "docsify")) "docs/_sidebar.md"
    )
}

# Assert that a render published everything it was supposed to.
#
# The existing snapshot tests cover the *content* of a handful of these files;
# what they cannot see is a page that was written somewhere the site never
# reaches, or one a generator quietly stopped emitting. Reporting the whole set
# of absentees at once, rather than one `expect_true(file_exists(...))` per
# path, keeps a broken render to a single legible failure.
#
# `except` drops paths a test has deliberately turned off, so that it can still
# assert the rest of the site is intact rather than checking only the one file
# it changed.
expect_published_docs <- function(tool, except = character(0)) {
    expected <- setdiff(published_docs_files(tool), except)
    absent <- expected[!fs::file_exists(expected)]
    expect_identical(absent, character(0))
}

# The generator tests below need a real render each, so this one checks the
# helper itself against a fixture in place --- no render, no skips, and it runs
# whether or not Quarto is installed.
#
# The failure it exists to catch is a silent one: a `published_docs_files()`
# that returned nothing, or lost a whole category, would leave every
# `expect_published_docs()` call passing vacuously while checking less and less.
test_that("published_docs_files covers every part of the site", {
    withr::local_dir(test_path("examples/testpkg.altdoc"))

    expect_identical(
        published_docs_files("docute"),
        c(
            "docs/index.html",
            "docs/reference.md",
            "docs/man/examplesIf_false.md",
            "docs/man/examplesIf_true.md",
            "docs/man/hello_base.md",
            "docs/man/hello_dontrun.md",
            "docs/man/hello_r6.md",
            # `here.pdf` is copied rather than rendered, so it alone keeps its
            # own extension.
            "docs/vignettes/here.pdf",
            "docs/vignettes/test.md",
            "docs/llms.txt"
        )
    )

    # quarto_website is the one generator that compiles the Markdown away, so
    # it is the only one whose man pages and reference index are `.html`.
    quarto <- published_docs_files("quarto_website")
    expect_true("docs/man/hello_base.html" %in% quarto)
    expect_true("docs/reference.html" %in% quarto)
    expect_false(any(grepl("\\.md$", quarto)))
    # A `.pdf` vignette is copied under every generator, this one included.
    expect_true("docs/vignettes/here.pdf" %in% quarto)

    # docsify publishes its nav as a file; nobody else does.
    expect_true("docs/_sidebar.md" %in% published_docs_files("docsify"))
    expect_false("docs/_sidebar.md" %in% published_docs_files("docute"))
})

test_that("published_docs_files handles a package with no vignettes", {
    # Three fixtures in this file ship no `vignettes/` --- `testpkg.altdoc.noURL`,
    # `testpkg.altdoc.nonGithubURL`, and `testpkg.lifecycle`. None of them uses
    # the helper today, so this pins the guard rather than an observed failure:
    # `fs::dir_ls()` errors on a missing directory, so without it a future
    # caller would get an ENOENT rather than a test failure naming the page.
    dir <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(dir, "man")))
    writeLines(
        c("\\name{f}", "\\alias{f}", "\\title{T}", "\\description{d}"),
        fs::path_join(c(dir, "man", "f.Rd"))
    )
    withr::local_dir(dir)

    out <- published_docs_files("docute")

    expect_true("docs/man/f.md" %in% out)
    expect_false(any(grepl("^docs/vignettes/", out)))
})

test_that("published_docs_files ignores vignette resource files", {
    # A resource under `vignettes/` is not a page: `.import_vignettes()` renders
    # only `.Rmd`/`.qmd`/`.md` (and copies `.pdf`), so expecting `refs.md` here
    # would blame the generator for a file it never claims to write.
    dir <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(dir, "man")))
    fs::dir_create(fs::path_join(c(dir, "vignettes")))
    writeLines("x", fs::path_join(c(dir, "vignettes", "intro.qmd")))
    writeLines("x", fs::path_join(c(dir, "vignettes", "refs.bib")))
    withr::local_dir(dir)

    out <- published_docs_files("docute")

    expect_true("docs/vignettes/intro.md" %in% out)
    expect_false(any(grepl("refs", out)))
})

test_that("docute: main files are correct", {
    skip_on_cran()
    skip_if(.is_windows() && .on_ci(), "Windows on CI")
    skip_if(!.quarto_is_installed())

    setup_example_package("testpkg.altdoc")

    ### generate docs
    install.packages(".", repos = NULL, type = "source")
    setup_docs("docute")
    render_docs(verbose = .on_ci())

    ### test
    expect_published_docs("docute")
    expect_snapshot_file("docs/README.md", variant = "docute")
    expect_snapshot_file("docs/docute.html", variant = "docute")
    expect_snapshot_file("docs/NEWS.md", variant = "docute")
    expect_snapshot_file("docs/reference.md", variant = "docute")
    expect_snapshot_file("docs/man/hello_base.md", variant = "docute")
    expect_snapshot_file("docs/man/hello_r6.md", variant = "docute")
    expect_snapshot_file("docs/man/examplesIf_true.md", variant = "docute")
    expect_snapshot_file("docs/man/examplesIf_false.md", variant = "docute")
    expect_snapshot_file("docs/man/hello_dontrun.md", variant = "docute")
    expect_snapshot_file("docs/vignettes/test.md", variant = "docute")
})

test_that("docsify: main files are correct", {
    skip_on_cran()
    skip_if(.is_windows() && .on_ci(), "Windows on CI")
    skip_if(!.quarto_is_installed())

    setup_example_package("testpkg.altdoc")

    ### generate docs
    install.packages(".", repos = NULL, type = "source")
    setup_docs("docsify")
    render_docs(verbose = .on_ci())

    ### test
    expect_published_docs("docsify")
    expect_snapshot_file("docs/README.md", variant = "docsify")
    expect_snapshot_file("docs/_sidebar.md", variant = "docsify")
    expect_snapshot_file("docs/NEWS.md", variant = "docsify")
    expect_snapshot_file("docs/reference.md", variant = "docsify")
    expect_snapshot_file("docs/man/hello_base.md", variant = "docsify")
    expect_snapshot_file("docs/man/hello_r6.md", variant = "docsify")
    expect_snapshot_file("docs/man/examplesIf_true.md", variant = "docsify")
    expect_snapshot_file("docs/man/examplesIf_false.md", variant = "docsify")
    expect_snapshot_file("docs/man/hello_dontrun.md", variant = "docsify")
    expect_snapshot_file("docs/vignettes/test.md", variant = "docsify")
    # This changes imperceptedly between windows and Linux/macOS, but the old
    # and new snapshots are LF so I don't really know why.
    skip_if(.is_windows())
    expect_snapshot_file("docs/index.html", variant = "docsify")
})

test_that("mkdocs: main files are correct", {
    skip_on_cran()
    skip_if_offline() # we download mkdocs every time
    skip_if(.is_windows() && .on_ci(), "Windows on CI")
    skip_if(!.quarto_is_installed())

    setup_example_package("testpkg.altdoc")

    ### special mkdocs stuff
    if (.is_windows()) {
        shell("python3 -m venv .venv_altdoc")
        shell(
            ".venv_altdoc\\Scripts\\activate.bat && python3 -m pip install mkdocs --quiet"
        )
    } else {
        system2("python3", "-m venv .venv_altdoc")
        system2(
            "bash",
            "-c 'source .venv_altdoc/bin/activate && python3 -m pip install mkdocs --quiet'",
            stdout = FALSE
        )
    }

    ### generate docs
    install.packages(".", repos = NULL, type = "source")
    setup_docs("mkdocs")
    render_docs(verbose = .on_ci())

    ### test
    # no good way to test the site structure ("docs/mkdocs.yml" only shows
    # the old yaml, not the one with replaced variables)
    expect_published_docs("mkdocs")
    expect_snapshot_file("docs/NEWS.md", variant = "mkdocs")
    expect_snapshot_file("docs/reference.md", variant = "mkdocs")
    expect_snapshot_file("docs/man/hello_base.md", variant = "mkdocs")
    expect_snapshot_file("docs/man/hello_r6.md", variant = "mkdocs")
    expect_snapshot_file("docs/man/hello_dontrun.md", variant = "mkdocs")
    expect_snapshot_file("docs/vignettes/test.md", variant = "mkdocs")
})

test_that("quarto: no error for basic workflow", {
    skip_on_cran()
    skip_if(.is_windows() && .on_ci(), "Windows on CI")
    skip_if(!.quarto_is_installed())

    setup_example_package("testpkg.altdoc")

    ### generate docs
    install.packages(".", repos = NULL, type = "source")
    setup_docs("quarto_website")
    expect_no_error(render_docs(verbose = .on_ci()))

    ### Quarto's own HTML changes between versions, so its content cannot be
    ### snapshotted --- but which pages it publishes can be, and that is the
    ### half that keeps going wrong.

    ### test
    expect_published_docs("quarto_website")
})

# The description is built from `tool` rather than shared across the loop, so a
# failure names the generator that produced it instead of leaving the reader to
# guess which pass it came from.
#
# Two generators rather than all four: `docute` builds straight into `docs/`,
# and `quarto_website` stages into a throwaway `_quarto/` that Quarto then
# renders into `docs/`. Those are the two shapes a publishing bug can take, and
# each further generator costs three more full renders of a path already
# covered.
for (tool in c("docute", "quarto_website")) {
    test_that(paste0(tool, ": re-rendering republishes the whole site"), {
        skip_on_cran()
        skip_if(.is_windows() && .on_ci(), "Windows on CI")
        skip_if(!.quarto_is_installed())

        setup_example_package("testpkg.altdoc")

        install.packages(".", repos = NULL, type = "source")
        setup_docs(tool)
        render_docs(verbose = .on_ci())
        expect_published_docs(tool)

        ### A second render lands in a `docs/` that is already populated, which
        ### no other test does. What this asserts is that every expected page is
        ### still there afterwards --- that re-rendering over an existing site
        ### does not drop one, which is a real failure mode for quarto_website,
        ### whose staged `_quarto/` is wiped at the start of every render.
        ###
        ### It does NOT catch a stale leftover: `expect_published_docs()` looks
        ### only for expected-but-absent files and never enumerates what is
        ### present, so a page a render stops producing would go unnoticed here.
        ### The opt-out check below is the one leftover assertion in this test,
        ### and it is deliberately file-specific.
        render_docs(verbose = .on_ci())
        expect_published_docs(tool)

        ### Opting out has to reach the published tree, not just the directory
        ### the generator was handed: `llms.txt` is written before
        ### quarto_website's staged build, so "not written this time" and "not
        ### on the site" are separate questions.
        writeLines("llms_txt: false", "altdoc/reference.yml")
        render_docs(verbose = .on_ci())
        expect_false(fs::file_exists("docs/llms.txt"))

        ### ...and taking one file away leaves the rest of the site standing.
        expect_published_docs(tool, except = "docs/llms.txt")
    })
}

# https://github.com/etiennebacher/altdoc/issues/307
test_that("quarto: no error for basic workflow, no Github URL", {
    skip_on_cran()
    skip_if(.is_windows() && .on_ci(), "Windows on CI")
    skip_if(!.quarto_is_installed())

    setup_example_package("testpkg.altdoc.noURL")

    install.packages(".", repos = NULL, type = "source")
    setup_docs("quarto_website")
    expect_no_error(render_docs(verbose = .on_ci()))
})

# https://github.com/etiennebacher/altdoc/issues/318
test_that("quarto: no error for basic workflow, non-GitHub URL", {
    skip_on_cran()
    skip_if(.is_windows() && .on_ci(), "Windows on CI")
    skip_if(!.quarto_is_installed())

    setup_example_package("testpkg.altdoc.nonGithubURL")

    install.packages(".", repos = NULL, type = "source")
    setup_docs("quarto_website")
    expect_no_error(render_docs(verbose = .on_ci()))
})

# https://github.com/etiennebacher/altdoc/issues/323
test_that("docsify: footer is still present even if URL is absent", {
    skip_on_cran()
    skip_if(.is_windows() && .on_ci(), "Windows on CI")
    skip_if(!.quarto_is_installed())

    create_local_package()

    setup_docs("docsify")
    render_docs()
    html <- .readlines("docs/index.html")
    expect_true(any(grepl("Documentation made with", html, fixed = TRUE)))
})

for (tool in c("docute", "docsify", "quarto_website")) {
    test_that("no error with different types of README", {
        skip_on_cran()
        skip_if(.is_windows() && .on_ci(), "Windows on CI")
        skip_if(!.quarto_is_installed())

        create_local_package()

        # README.md
        cat("hello there", file = "README.md")
        setup_docs(tool)
        expect_no_error(render_docs(verbose = .on_ci()))
        fs::dir_delete("docs")

        # README.Rmd
        cat("hello there", file = "README.Rmd")
        expect_no_error(render_docs(verbose = .on_ci()))
        fs::dir_delete("docs")
        fs::file_delete("README.Rmd")

        # README.qmd
        cat("hello there", file = "README.qmd")
        expect_no_error(render_docs(verbose = .on_ci()))
    })
}

test_that("quarto: autolink", {
    skip_on_cran()
    skip_if(.is_windows() && .on_ci(), "Windows on CI")
    skip_if(!.quarto_is_installed())

    setup_example_package("testpkg.altdoc")

    ### generate docs
    install.packages(".", repos = NULL, type = "source")
    setup_docs("quarto_website")
    expect_no_error(render_docs(verbose = .on_ci()))

    tmp <- .readlines("docs/vignettes/test.html")
    expect_true(
        any(grepl("https://rdrr.io/r/base/library.html", tmp, fixed = TRUE))
    )
})

test_that("quarto: pkgdown.yml is at docs root after render_docs", {
    skip_on_cran()
    skip_if(.is_windows() && .on_ci(), "Windows on CI")
    skip_if(!.quarto_is_installed())

    setup_example_package("testpkg.altdoc")
    desc::desc_add_urls("https://mywebsite.com")

    ### generate docs
    install.packages(".", repos = NULL, type = "source")
    setup_docs("quarto_website")
    expect_no_error(render_docs(verbose = .on_ci()))

    ### pkgdown.yml must be at the root of docs/ so that downlit can find it at
    ### <url>/pkgdown.yml when auto-linking function calls in vignettes
    expect_true(fs::file_exists("docs/pkgdown.yml"))
    docs_pkgdown <- yaml::read_yaml("docs/pkgdown.yml")
    expect_equal(docs_pkgdown$urls$reference, "https://mywebsite.com/man")
})

test_that("files in man/figures are copied to docs/help/figures", {
    skip_on_cran()
    skip_if(!.quarto_is_installed())
    setup_example_package("testpkg.lifecycle")

    ### generate docs
    install.packages(".", repos = NULL, type = "source")
    setup_docs("docute")
    expect_no_error(render_docs(verbose = .on_ci()))
    expect_true(fs::file_exists("docs/help/figures/lifecycle-experimental.svg"))
    md <- .readlines("docs/man/foo.md")
    expect_true(any(grepl(
        "../help/figures/lifecycle-experimental.svg",
        md,
        fixed = TRUE
    )))

    ### re-rendering works
    expect_no_error(render_docs(verbose = .on_ci()))
})

test_that("mkdocs: index.html is reset at every render_docs(), #336", {
    skip_on_cran()
    skip_if_offline() # we download mkdocs every time
    skip_if(.is_windows())
    skip_if(!.quarto_is_installed())

    ### setup: create a temp package using the structure of testpkg.altdoc
    create_local_package()
    fs::dir_delete("R")

    system2("python3", "-m venv .venv_altdoc")
    system2(
        "bash",
        "-c 'source .venv_altdoc/bin/activate && python3 -m pip install mkdocs mkdocs-material --quiet'",
        stdout = FALSE
    )

    ### generate docs
    install.packages(".", repos = NULL, type = "source")
    setup_docs("mkdocs")

    ### Custom overrides partial
    fs::dir_create("altdoc/overrides/partials")
    cat("HELLO THERE", file = "altdoc/overrides/partials/copyright.html")
    cat(
        "site_name: foo
theme:
  name: material
  custom_dir: altdoc/overrides",
        file = "altdoc/mkdocs.yml"
    )

    render_docs(verbose = .on_ci())
    expect_true(any(grepl(
        "HELLO THERE",
        .readlines("docs/index.html"),
        fixed = TRUE
    )))

    ### Ensure that the overrides/partial is updated
    cat("HELLO AGAIN", file = "altdoc/overrides/partials/copyright.html")
    render_docs(verbose = .on_ci())
    expect_false(any(grepl(
        "HELLO THERE",
        .readlines("docs/index.html"),
        fixed = TRUE
    )))
    expect_true(any(grepl(
        "HELLO AGAIN",
        .readlines("docs/index.html"),
        fixed = TRUE
    )))
})

test_that("quarto_website: ensure that README.md is preferred over README.qmd", {
    skip_on_cran()
    skip_if(.is_windows() && .on_ci(), "Windows on CI")
    skip_if(!.quarto_is_installed())

    create_local_package()

    cat("hello there", file = "README.md")
    cat("---hello there\nhello again", file = "README.qmd")
    setup_docs("quarto_website")
    render_docs(verbose = .on_ci())
    expect_false(any(grepl(
        "hello again",
        .readlines("docs/index.html"),
        fixed = TRUE
    )))
})

test_that(".add_pkgdown() works", {
    skip_on_cran()
    skip_if(.is_windows() && .on_ci(), "Windows on CI")
    skip_if(!.quarto_is_installed())

    setup_example_package("testpkg.altdoc")
    desc::desc_add_urls("https://mywebsite.com")

    timestamp_regex <- "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\+\\d{4}"

    ### generate docs
    install.packages(".", repos = NULL, type = "source")
    setup_docs("docute")
    expect_snapshot(
        cat(.readlines("altdoc/pkgdown.yml"), sep = "\n"),
        transform = function(x) {
            first_timestamp <<- regmatches(x, gregexpr(timestamp_regex, x)) |>
                unlist()
            x <- gsub("\\d+\\.\\d+\\.\\d+(\\.\\d+|)", "0.0.0", x)
            x <- gsub(
                timestamp_regex,
                "2020-01-01T00:00:00+0000",
                x
            )
            x
        }
    )

    ### There are not many fields that are updated because if they were created
    ### by the user then we don't want to overwrite them.
    ### render_docs() should update pkgdown.yml with a new timestamp, so we can
    ### check that it is different than the initial one.
    Sys.sleep(1)
    render_docs()
    content <- .readlines("altdoc/pkgdown.yml")
    second_timestamp <- regmatches(
        content,
        gregexpr(timestamp_regex, content)
    ) |>
        unlist()

    expect_true(first_timestamp != second_timestamp)

    ### pkgdown.yml must be at the root of docs/ so that downlit can find it at
    ### <url>/pkgdown.yml when auto-linking function calls in vignettes
    expect_true(fs::file_exists("docs/pkgdown.yml"))
    docs_pkgdown <- yaml::read_yaml("docs/pkgdown.yml")
    expect_equal(docs_pkgdown$urls$reference, "https://mywebsite.com/man")

    ### render_docs() doesn't remove pre-existing fields in pkgdown.yml
    cat(
        "altdoc: 0.0.0
pandoc: 0.0.0
pkgdown: 0.0.0
last_built: 2020-01-01T00:00:00+0000
articles:
  polars: polars.html
  install: install.html
urls:
  reference: https://anotherwebsite.com/man
  article: https://anotherwebsite.com/vignettes\n",
        file = "altdoc/pkgdown.yml"
    )
    render_docs()
    expect_snapshot(
        cat(.readlines("altdoc/pkgdown.yml"), sep = "\n"),
        transform = function(x) {
            x <- gsub("\\d+\\.\\d+\\.\\d+(\\.\\d+|)", "0.0.0", x)
            x <- gsub(
                "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\+\\d{4}",
                "2020-01-01T00:00:00+0000",
                x
            )
            x
        }
    )
})

# Test failures ------------------------------

test_that("render_docs errors if vignettes fail", {
    skip_on_cran()
    skip_if(!.quarto_is_installed())
    create_local_package()
    fs::dir_create("vignettes")
    cat("# Get Started\n```{r}\n1 +\n```\n", file = "vignettes/foo.Rmd")
    setup_docs("docute", path = getwd())
    expect_error(
        render_docs(path = getwd()),
        "some failures when rendering vignettes"
    )
})

test_that("render_docs errors if man fail", {
    skip_on_cran()
    skip_if(!.quarto_is_installed())
    create_local_package()
    fs::dir_create("man")
    cat(
        "\\name{hi}\n\\title{hi}\n\\usage{\nhi()\n}\n\\examples{\n1 +\n}\n",
        file = "man/foo.Rd"
    )
    setup_docs("docute", path = getwd())
    expect_error(
        render_docs(path = getwd()),
        "some failures when rendering man pages"
    )
})

# Test for recursive vignette discovery in subfolders
test_that("quarto_website: recursive vignette discovery in subfolders", {
    skip_on_cran()
    skip_if(.is_windows() && .on_ci(), "Windows on CI")
    skip_if(!.quarto_is_installed())

    ### setup: create a temp package using the structure of testpkg.recursive
    setup_example_package("testpkg.recursive")

    ### generate docs
    install.packages(".", repos = NULL, type = "source")
    setup_docs("quarto_website")
    expect_no_error(render_docs(verbose = .on_ci()))

    ### test that vignettes in subfolders are rendered
    expect_published_docs("quarto_website")
    expect_true(fs::file_exists("docs/vignettes/articles/article_test.html"))

    ### ...and that the machine-readable index knows about them. Rendering a
    ### nested article and listing it are separate steps, and the file being on
    ### the site is exactly what makes a missing entry easy to overlook: the
    ### page loads for anyone who navigates to it, and only a consumer reading
    ### `llms.txt` finds it absent.
    llms <- .readlines("docs/llms.txt")
    expect_true(any(grepl(
        "vignettes/articles/article_test.html",
        llms,
        fixed = TRUE
    )))
})

# The docsify and mkdocs counterparts of the test above. These two discover
# `vignettes/` recursively themselves rather than handing the tree to Quarto,
# so each of the three steps -- render it, link it, index it -- is separately
# capable of dropping a nested page, and each is asserted separately below.
#
# The link assertion is the one worth keeping honest: publishing a page nobody
# links to is the exact state this fixture was in before, and it is invisible
# to a file-existence check.
test_that("docsify: recursive vignette discovery in subfolders", {
    skip_on_cran()
    skip_if(.is_windows() && .on_ci(), "Windows on CI")
    skip_if(!.quarto_is_installed())

    ### setup: create a temp package using the structure of testpkg.recursive
    setup_example_package("testpkg.recursive")

    ### generate docs
    install.packages(".", repos = NULL, type = "source")
    setup_docs("docsify")
    expect_no_error(render_docs(verbose = .on_ci()))

    ### rendered, not merely copied in as its `.qmd` source
    expect_published_docs("docsify")
    expect_true(fs::file_exists("docs/vignettes/articles/article_test.md"))

    ### linked from the nav, with the path it was published at and the title
    ### read from its own front matter rather than its file name
    sidebar <- .readlines("docs/_sidebar.md")
    expect_true(any(grepl(
        "[Article in subfolder](vignettes/articles/article_test.md)",
        sidebar,
        fixed = TRUE
    )))

    ### ...and listed in the machine-readable index
    llms <- .readlines("docs/llms.txt")
    expect_true(any(grepl(
        "vignettes/articles/article_test.md",
        llms,
        fixed = TRUE
    )))
})

test_that("mkdocs: recursive vignette discovery in subfolders", {
    skip_on_cran()
    skip_if_offline()
    skip_if(.is_windows() && .on_ci(), "Windows on CI")
    skip_if(!.quarto_is_installed())
    skip_if(!.venv_exists())

    ### setup: create a temp package using the structure of testpkg.recursive
    setup_example_package("testpkg.recursive")

    ### generate docs
    install.packages(".", repos = NULL, type = "source")
    setup_docs("mkdocs")
    expect_no_error(render_docs(verbose = .on_ci()))

    ### rendered, not merely copied in as its `.qmd` source
    expect_published_docs("mkdocs")
    expect_true(fs::file_exists("docs/vignettes/articles/article_test.md"))

    ### mkdocs built a page from it, which is what proves the nav entry
    ### reached mkdocs rather than only the file
    expect_true(fs::file_exists(
        "docs/vignettes/articles/article_test/index.html"
    ))

    ### ...and listed in the machine-readable index
    llms <- .readlines("docs/llms.txt")
    expect_true(any(grepl(
        "vignettes/articles/article_test.md",
        llms,
        fixed = TRUE
    )))
})

# Test for singleton entries in custom sidebars
test_that("quarto_website: singleton entries in custom sidebars", {
    skip_on_cran()
    skip_if(.is_windows() && .on_ci(), "Windows on CI")
    skip_if(!.quarto_is_installed())

    ### setup: create a temp package using the structure of testpkg.singleton
    setup_example_package("testpkg.singleton")

    ### generate docs
    ### no setup_docs() call: the example package already ships a custom
    ### altdoc/quarto_website.yml with the singleton entry to test, and
    ### setup_docs() would abort on (or overwrite) that existing file
    install.packages(".", repos = NULL, type = "source")

    ### test that the custom sidebar with singleton entries renders without error
    expect_no_error(render_docs(verbose = .on_ci()))
})
