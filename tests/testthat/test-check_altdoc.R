# A throwaway package with an `altdoc/` settings file, for the checks that read
# one. `settings` is the settings file's lines; `...` is passed as
# name = c("<line>", ...) to write further files under the package root, so a
# test can add the `NEWS.md` or `man/*.Rd` its own case needs.
local_check_package <- function(
    settings = character(0),
    tool = "docute",
    ...,
    env = parent.frame()
) {
    dir <- withr::local_tempdir(.local_envir = env)
    writeLines(
        c(
            "Package: checktest",
            "Version: 0.0.1",
            "Title: T",
            "Description: D.",
            "License: MIT"
        ),
        fs::path_join(c(dir, "DESCRIPTION"))
    )
    fs::dir_create(fs::path_join(c(dir, "altdoc")))
    fn <- switch(
        tool,
        docute = "docute.html",
        docsify = "docsify.md",
        mkdocs = "mkdocs.yml",
        quarto_website = "quarto_website.yml"
    )
    writeLines(settings, fs::path_join(c(dir, "altdoc", fn)))

    files <- list(...)
    for (nm in names(files)) {
        target <- fs::path_join(c(dir, nm))
        fs::dir_create(fs::path_dir(target))
        writeLines(files[[nm]], target)
    }
    dir
}

# The .Rd content of a minimal documented topic.
check_rd <- function(name) {
    c(
        sprintf("\\name{%s}", name),
        sprintf("\\alias{%s}", name),
        "\\title{A topic}",
        "\\description{d}"
    )
}

test_that(".check_altdoc_variables flags a variable altdoc does not know", {
    dir <- local_check_package("link: $ALTDOC_TYPO")

    out <- .check_altdoc_variables(dir, "docute")

    expect_length(out, 1L)
    expect_match(out, "ALTDOC_TYPO", fixed = TRUE)
    expect_match(out, "does not recognize")
})

test_that(".check_altdoc_variables says nothing about a variable that resolves", {
    dir <- local_check_package("link: $ALTDOC_NEWS", NEWS.md = "# News")

    expect_identical(.check_altdoc_variables(dir, "docute"), character(0))
})

test_that(".check_altdoc_variables accepts an `inst/` source", {
    # The `inst/` and `.Rd` candidates are the ones #58 found even altdoc's own
    # docs had omitted, so a check that only knew `NEWS.md` would wrongly
    # report a package shipping `inst/NEWS.Rd`.
    dir <- local_check_package(
        "link: $ALTDOC_NEWS",
        `inst/NEWS.Rd` = "\\name{NEWS}\\title{News}"
    )

    expect_identical(.check_altdoc_variables(dir, "docute"), character(0))
})

test_that(".check_altdoc_variables treats LICENSE and LICENCE as alternatives", {
    # The shipped templates list both spellings and rely on the unresolved line
    # being dropped, so reporting the missing half would fire on every default
    # project. Only "neither resolves" is a finding.
    settings <- c("a: $ALTDOC_LICENSE", "b: $ALTDOC_LICENCE")

    with_one <- local_check_package(settings, LICENSE.md = "MIT")
    expect_identical(.check_altdoc_variables(with_one, "docute"), character(0))

    with_neither <- local_check_package(settings)
    out <- .check_altdoc_variables(with_neither, "docute")
    expect_length(out, 1L)
    expect_match(out, "ALTDOC_LICENSE", fixed = TRUE)
    expect_match(out, "ALTDOC_LICENCE", fixed = TRUE)
})

test_that(".check_altdoc_variables names only the spellings a file uses", {
    # Resolution is judged across the whole group, but a template using one
    # spelling should not be told it uses both.
    dir <- local_check_package("b: $ALTDOC_LICENCE")

    out <- .check_altdoc_variables(dir, "docute")

    expect_match(out, "ALTDOC_LICENCE", fixed = TRUE)
    expect_false(grepl("$ALTDOC_LICENSE", out, fixed = TRUE))
})

test_that(".check_altdoc_variables also reads docsify's body template", {
    # docsify is the one generator whose variables live in two files, and
    # `docsify.html` is substituted by `.settings_docsify()` rather than by
    # `.import_settings()` --- so a check reading only the sidebar would pass a
    # typo in the body.
    dir <- local_check_package(character(0), tool = "docsify")
    writeLines(
        "<a href='$ALTDOC_NOT_A_VARIABLE'>",
        fs::path_join(c(dir, "altdoc", "docsify.html"))
    )

    out <- .check_altdoc_variables(dir, "docsify")

    expect_length(out, 1L)
    expect_match(out, "docsify.html", fixed = TRUE)
})

test_that(".check_altdoc_nav says nothing when the block variable is used", {
    dir <- local_check_package(
        "sidebar: $ALTDOC_MAN_BLOCK",
        `man/hello.Rd` = check_rd("hello")
    )

    expect_identical(.check_altdoc_nav(dir, "docute", "man"), character(0))
})

test_that(".check_altdoc_nav flags a topic a hand-written nav omits", {
    dir <- local_check_package(
        "{title: 'Hello', link: 'man/hello.md'}",
        `man/hello.Rd` = check_rd("hello"),
        `man/lonely.Rd` = check_rd("lonely")
    )

    out <- .check_altdoc_nav(dir, "docute", "man")

    expect_length(out, 1L)
    expect_match(out, "lonely", fixed = TRUE)
    expect_false(grepl("hello", out, fixed = TRUE))
})

test_that(".check_altdoc_nav matches a mangled topic by its file name", {
    # roxygen2 writes `%+%` to `grapes-plus-grapes.Rd`, and the published page
    # is named after the file --- so the nav links the file name, which is what
    # the check has to compare against.
    dir <- local_check_package(
        "{title: '%+%', link: 'man/grapes-plus-grapes.md'}",
        `man/grapes-plus-grapes.Rd` = c(
            "\\name{\\%+\\%}",
            "\\alias{\\%+\\%}",
            "\\title{Concatenate}",
            "\\description{d}"
        )
    )

    expect_identical(.check_altdoc_nav(dir, "docute", "man"), character(0))
})

test_that(".check_altdoc_nav flags a vignette a hand-written nav omits", {
    dir <- local_check_package(
        "{title: 'Intro', link: 'vignettes/intro.md'}",
        `vignettes/intro.qmd` = "# Intro",
        `vignettes/forgotten.qmd` = "# Forgotten"
    )

    out <- .check_altdoc_nav(dir, "docute", "vignettes")

    expect_length(out, 1L)
    expect_match(out, "forgotten", fixed = TRUE)
})

test_that(".check_altdoc_nav reads vignettes from the source tree", {
    # `check_altdoc()` is meant to run before a render, so reading a rendered
    # `docs/` would report every page as missing on a package nobody has
    # rendered yet --- the state a first-time user is in.
    dir <- local_check_package(
        "sidebar: none",
        `vignettes/intro.qmd` = "# Intro"
    )
    expect_false(fs::dir_exists(fs::path_join(c(dir, "docs"))))

    out <- .check_altdoc_nav(dir, "docute", "vignettes")

    expect_length(out, 1L)
    expect_match(out, "intro", fixed = TRUE)
})

test_that(".check_altdoc_urls flags a package with no URL", {
    dir <- local_check_package()

    out <- .check_altdoc_urls(dir)

    expect_length(out, 1L)
    expect_match(out, "no `URL:`", fixed = TRUE)
})

test_that(".check_altdoc_urls flags a URL that is only a repository", {
    dir <- local_check_package()
    desc::desc_set_urls("https://github.com/foo/bar", file = dir)

    out <- .check_altdoc_urls(dir)

    expect_length(out, 1L)
    expect_match(out, "code-hosting repository")
})

test_that(".check_altdoc_urls accepts a real site URL", {
    dir <- local_check_package()
    desc::desc_set_urls(
        c("https://foo.github.io/bar", "https://github.com/foo/bar"),
        file = dir
    )

    expect_identical(.check_altdoc_urls(dir), character(0))
})

test_that(".check_altdoc_urls flags a pkgdown.yml that disagrees with DESCRIPTION", {
    skip_if_not_installed("yaml")
    dir <- local_check_package()
    desc::desc_set_urls("https://foo.github.io/bar", file = dir)
    writeLines(
        c("urls:", "  reference: https://elsewhere.example.com/man"),
        fs::path_join(c(dir, "altdoc", "pkgdown.yml"))
    )

    out <- .check_altdoc_urls(dir)

    expect_length(out, 1L)
    expect_match(out, "one of the two is stale")
})

test_that(".check_altdoc_reference reports an invalid reference.yml", {
    dir <- local_check_package(
        "sidebar: $ALTDOC_MAN_BLOCK",
        `man/hello.Rd` = check_rd("hello"),
        `altdoc/reference.yml` = c("titel: Typo")
    )

    out <- .check_altdoc_reference(dir)

    expect_length(out, 1L)
    expect_match(out, "Unknown top-level key")
})

test_that(".check_altdoc_reference reports a topic that does not exist", {
    dir <- local_check_package(
        "sidebar: $ALTDOC_MAN_BLOCK",
        `man/hello.Rd` = check_rd("hello"),
        `altdoc/reference.yml` = c(
            "reference:",
            "  - title: All",
            "    contents:",
            "      - no_such_topic"
        )
    )

    out <- .check_altdoc_reference(dir)

    expect_length(out, 1L)
    expect_match(out, "not a known topic name or alias")
})

test_that(".check_altdoc_reference accepts a valid reference.yml", {
    dir <- local_check_package(
        "sidebar: $ALTDOC_MAN_BLOCK",
        `man/hello.Rd` = check_rd("hello"),
        `altdoc/reference.yml` = c(
            "reference:",
            "  - title: All",
            "    contents:",
            "      - hello"
        )
    )

    expect_identical(.check_altdoc_reference(dir), character(0))
})

test_that(".check_altdoc_reference says nothing when there is no reference.yml", {
    dir <- local_check_package("sidebar: $ALTDOC_MAN_BLOCK")

    expect_identical(.check_altdoc_reference(dir), character(0))
})

test_that("check_altdoc reports every finding rather than the first", {
    # The point of the entry function: one call lists everything to fix. A
    # fixture tripping a single check could not tell that from
    # abort-on-first-problem.
    dir <- local_check_package(
        c("a: $ALTDOC_TYPO", "b: 'man/hello.md'"),
        `man/hello.Rd` = check_rd("hello"),
        `man/lonely.Rd` = check_rd("lonely")
    )

    out <- suppressMessages(check_altdoc(dir))

    expect_gte(length(out), 3L)
    expect_true(any(grepl("ALTDOC_TYPO", out, fixed = TRUE)))
    expect_true(any(grepl("lonely", out, fixed = TRUE)))
    expect_true(any(grepl("no `URL:`", out, fixed = TRUE)))
})

test_that("check_altdoc returns its findings invisibly", {
    dir <- local_check_package("sidebar: $ALTDOC_MAN_BLOCK")

    expect_invisible(suppressMessages(check_altdoc(dir)))
})

test_that("check_altdoc reports success on a clean project", {
    dir <- local_check_package(
        c("sidebar: $ALTDOC_MAN_BLOCK", "articles: $ALTDOC_VIGNETTE_BLOCK"),
        `man/hello.Rd` = check_rd("hello")
    )
    desc::desc_set_urls("https://foo.github.io/bar", file = dir)

    expect_message(
        expect_identical(check_altdoc(dir), character(0)),
        "No problems found"
    )
})

test_that(".check_altdoc_variables quotes the reason for the spelling used", {
    # Resolution is judged across the alternatives group, but the advice has to
    # name the file that would fix the variable in front of the reader. Quoting
    # the first group member's reason regardless sent a file using only
    # `$ALTDOC_CHANGELOG` after a `NEWS` file, which would not resolve it.
    dir <- local_check_package("b: $ALTDOC_CHANGELOG")

    out <- .check_altdoc_variables(dir, "docute")

    expect_match(out, "no CHANGELOG file was found", fixed = TRUE)
    expect_false(grepl("no NEWS file was found", out, fixed = TRUE))
})

test_that(".check_altdoc_reference reports a warning and keeps checking", {
    # `tryCatch(warning = )` installs an exiting handler, so the warning would
    # end the function and hide the error below it --- the one that actually
    # aborts a render. Both have to be reported.
    dir <- local_check_package(
        "sidebar: $ALTDOC_MAN_BLOCK",
        `man/hello.Rd` = check_rd("hello"),
        `altdoc/reference.yml` = c(
            "sidebar_label_width: 60",
            "reference:",
            "  - title: All",
            "    contents:",
            "      - no_such_topic"
        )
    )

    out <- .check_altdoc_reference(dir)

    expect_length(out, 2L)
    expect_true(any(grepl("no effect", out)))
    expect_true(any(grepl("not a known topic name or alias", out)))
})

test_that(".check_altdoc_nav does not count a prefix of another page as linked", {
    # `plot` is a substring of `plot_group`, so an unanchored match let the
    # entry for one page vouch for the other. Name-prefix families are ordinary
    # in R packages.
    dir <- local_check_package(
        "{title: 'Plot group', link: 'man/plot_group.md'}",
        `man/plot.Rd` = check_rd("plot"),
        `man/plot_group.Rd` = check_rd("plot_group")
    )

    out <- .check_altdoc_nav(dir, "docute", "man")

    expect_length(out, 1L)
    expect_match(out, "`plot`", fixed = TRUE)
})

test_that(".check_altdoc_nav treats $ALTDOC_REFERENCE as reaching every topic", {
    # The generated index lists every non-internal topic, so a nav that keeps
    # the index line but drops the per-page block still reaches them all ---
    # two clicks rather than one. The shipped templates carry both lines, so
    # dropping one is an ordinary customization.
    dir <- local_check_package(
        "{title: 'Reference', link: '$ALTDOC_REFERENCE'}",
        `man/hello.Rd` = check_rd("hello")
    )

    expect_identical(.check_altdoc_nav(dir, "docute", "man"), character(0))
})

test_that(".check_altdoc_nav still checks vignettes under $ALTDOC_REFERENCE", {
    # The reference index lists topics, not articles, and altdoc builds no
    # articles index (#36) --- so it must not exempt a vignette.
    dir <- local_check_package(
        "{title: 'Reference', link: '$ALTDOC_REFERENCE'}",
        `vignettes/intro.qmd` = "# Intro"
    )

    out <- .check_altdoc_nav(dir, "docute", "vignettes")

    expect_length(out, 1L)
    expect_match(out, "intro", fixed = TRUE)
})

test_that("check_altdoc prints a finding containing braces without erroring", {
    # Findings carry text altdoc only relays, and cli runs each item through
    # glue: `{foo}` aborts the whole call ("Could not evaluate cli `{}`
    # expression"), and a bare `{}` is silently deleted. Either defeats the
    # report-do-not-abort design this function is built on.
    #
    # `altdoc/pkgdown.yml` is hand-edited, so an unexpanded template
    # placeholder left in a URL is an ordinary way for a brace to reach a
    # finding --- and the URL is quoted back verbatim in the message.
    skip_if_not_installed("yaml")
    dir <- local_check_package("sidebar: $ALTDOC_MAN_BLOCK")
    desc::desc_set_urls("https://foo.github.io/bar", file = dir)
    writeLines(
        c("urls:", "  reference: https://example.com/{version}/man"),
        fs::path_join(c(dir, "altdoc", "pkgdown.yml"))
    )

    expect_no_error(out <- suppressMessages(check_altdoc(dir)))

    expect_length(out, 1L)
    # The finding keeps the braces; only what cli is handed is escaped.
    expect_match(out, "{version}", fixed = TRUE)
})

test_that(".escape_braces doubles both braces", {
    expect_identical(.escape_braces("a {} b"), "a {{}} b")
    expect_identical(.escape_braces("x {foo} y"), "x {{foo}} y")
})

test_that(".escape_regex quotes a mangled topic name", {
    # `sub-.foo`'s `.` would otherwise match any character, so an unrelated
    # `sub-Xfoo` entry in the nav would vouch for it.
    expect_false(grepl(paste0(.escape_regex("sub-.foo"), "$"), "sub-Xfoo"))
    expect_true(grepl(paste0(.escape_regex("sub-.foo"), "$"), "sub-.foo"))
})

test_that(".check_altdoc_sidebar_fold says nothing when the setting is absent", {
    dir <- local_check_package(
        "    include-in-header: $ALTDOC_SIDEBAR_FOLD",
        tool = "quarto_website"
    )
    expect_identical(
        .check_altdoc_sidebar_fold(dir, "quarto_website"),
        character(0)
    )
})

test_that(".check_altdoc_sidebar_fold says nothing when the variable is used", {
    dir <- local_check_package(
        "    include-in-header: $ALTDOC_SIDEBAR_FOLD",
        tool = "quarto_website",
        `altdoc/reference.yml` = "sidebar_fold: collapsed"
    )
    expect_identical(
        .check_altdoc_sidebar_fold(dir, "quarto_website"),
        character(0)
    )
})

test_that(".check_altdoc_sidebar_fold flags a setting with no control", {
    dir <- local_check_package(
        "    include-in-header: header.html",
        tool = "quarto_website",
        `altdoc/reference.yml` = "sidebar_fold: collapsed"
    )
    out <- .check_altdoc_sidebar_fold(dir, "quarto_website")
    expect_length(out, 1)
    expect_match(out, "ALTDOC_SIDEBAR_FOLD", fixed = TRUE)
})

test_that(".check_altdoc_sidebar_fold flags a generator that cannot use it", {
    # `expanded` is the default, so this fires on the key being present rather
    # than on the value asking for anything.
    dir <- local_check_package(
        character(0),
        tool = "docute",
        `altdoc/reference.yml` = "sidebar_fold: expanded"
    )
    out <- .check_altdoc_sidebar_fold(dir, "docute")
    expect_length(out, 1)
    expect_match(out, "docute", fixed = TRUE)
})

test_that("check_altdoc() reports a sidebar_fold with no control", {
    dir <- local_check_package(
        "    include-in-header: header.html",
        tool = "quarto_website",
        `altdoc/reference.yml` = "sidebar_fold: collapsed"
    )
    out <- suppressMessages(check_altdoc(dir))
    expect_true(any(grepl("ALTDOC_SIDEBAR_FOLD", out, fixed = TRUE)))
})

test_that("check_altdoc() does not leak the sidebar_label_width warning", {
    # `sidebar_label_width` alone makes `.reference_settings()` warn, and every
    # caller inside `check_altdoc()` reads the same file --- so a caller that
    # does not muffle turns one finding into a finding plus a raw R warning
    # printed outside the findings list.
    dir <- local_check_package(
        "    include-in-header: header.html",
        tool = "quarto_website",
        `altdoc/reference.yml` = c(
            "sidebar_label_width: 60",
            "sidebar_fold: collapsed"
        )
    )

    expect_no_warning(.check_altdoc_sidebar_fold(dir, "quarto_website"))

    warnings <- character(0)
    out <- withCallingHandlers(
        suppressMessages(check_altdoc(dir)),
        warning = function(w) {
            warnings <<- c(warnings, conditionMessage(w))
            invokeRestart("muffleWarning")
        }
    )
    expect_identical(warnings, character(0))

    # Muffled, not lost: the width finding is still reported, exactly once, by
    # the check that owns it.
    width <- grepl("sidebar_label_width", out, fixed = TRUE)
    expect_length(out[width], 1)
})
