# A package with two public topics, one internal one, and a mangled name, so a
# single fixture exercises grouping, the internal-topic rule, and the
# name/file divergence.
local_sidebar_package <- function(reference = NULL, env = parent.frame()) {
    dir <- local_man_package(
        alpha = c(
            "\\name{alpha}",
            "\\alias{alpha}",
            "\\title{First thing}",
            "\\description{d}",
            "\\usage{alpha()}"
        ),
        beta = c(
            "\\name{beta}",
            "\\alias{beta}",
            "\\title{Second thing}",
            "\\description{d}",
            "\\usage{beta()}"
        ),
        helper = c(
            "\\name{helper}",
            "\\alias{helper}",
            "\\title{An internal helper}",
            "\\description{d}",
            "\\keyword{internal}"
        ),
        `grapes-plus-grapes` = c(
            "\\name{\\%+\\%}",
            "\\alias{\\%+\\%}",
            "\\title{Concatenate}",
            "\\description{d}"
        ),
        env = env
    )
    if (!is.null(reference)) {
        fs::dir_create(fs::path_join(c(dir, "altdoc")))
        writeLines(reference, fs::path_join(c(dir, "altdoc", "reference.yml")))
    }
    dir
}

# The published pages a rendered package would have, in the order
# `.sidebar_vignettes_quarto_website()` globs them.
published_pages <- function(dir) {
    files <- sort(list.files(fs::path_join(c(dir, "man")), pattern = "\\.Rd$"))
    paste0("man/", sub("\\.Rd$", "", files), ".qmd")
}

# Flatten the nested structure to "Section > label" strings, which is what a
# reader actually sees, and is stable against the list shape.
flatten_sidebar <- function(contents, prefix = character()) {
    out <- character()
    for (item in contents) {
        if (!is.null(item$section)) {
            out <- c(
                out,
                flatten_sidebar(item$contents, c(prefix, item$section))
            )
        } else {
            out <- c(out, paste(c(prefix, item$text), collapse = " > "))
        }
    }
    out
}

test_that("without reference.yml the Reference section stays a flat list", {
    dir <- local_sidebar_package()
    fn_man <- published_pages(dir)

    labels <- sub("^man/", "", fn_man)
    out <- .sidebar_man_contents(fn_man, labels, src_dir = dir)

    # No nesting at all, and every published page is still listed -- including
    # the internal one, which is what the flat sidebar has always done.
    expect_null(unlist(lapply(out, function(x) x$section)))
    expect_identical(
        vapply(out, function(x) x$file, character(1)),
        fn_man
    )
})

test_that("reference.yml sections become nested sidebar sections", {
    dir <- local_sidebar_package(c(
        "reference:",
        "  - title: Core",
        "    contents:",
        "      - alpha",
        "  - title: Extras",
        "    contents:",
        "      - beta"
    ))
    fn_man <- published_pages(dir)

    labels <- sub("^man/", "", fn_man)
    out <- .sidebar_man_contents(fn_man, labels, src_dir = dir)

    expect_identical(
        vapply(out, function(x) x$section, character(1)),
        c("Core", "Extras", "Other")
    )
    expect_identical(
        flatten_sidebar(out),
        c(
            "Core > alpha.qmd",
            "Extras > beta.qmd",
            # `%+%` is documented in grapes-plus-grapes.Rd, so the entry links
            # to the page that file produced rather than to `man/%+%`.
            "Other > grapes-plus-grapes.qmd"
        )
    )
})

test_that("internal topics are dropped once sections are declared", {
    dir <- local_sidebar_package(c(
        "reference:",
        "  - title: Core",
        "    contents:",
        "      - alpha"
    ))
    fn_man <- published_pages(dir)

    labels <- sub("^man/", "", fn_man)
    out <- .sidebar_man_contents(fn_man, labels, src_dir = dir)

    # `helper` has a published page and is reachable, but `\keyword{internal}`
    # keeps it off the index page, and the sidebar now agrees.
    expect_false(any(grepl("helper", flatten_sidebar(out))))
})

test_that("sections keep their declared order, and topics theirs within one", {
    dir <- local_sidebar_package(c(
        "reference:",
        "  - title: Second",
        "    contents:",
        "      - beta",
        "      - alpha",
        "  - title: First",
        "    contents:",
        "      - '%+%'"
    ))
    fn_man <- published_pages(dir)

    labels <- sub("^man/", "", fn_man)
    out <- .sidebar_man_contents(fn_man, labels, src_dir = dir)

    expect_identical(
        flatten_sidebar(out),
        c(
            "Second > beta.qmd",
            "Second > alpha.qmd",
            "First > grapes-plus-grapes.qmd"
        )
    )
})

test_that("a section with no title contributes its topics without a wrapper", {
    dir <- local_sidebar_package(c(
        "reference:",
        "  - contents:",
        "      - alpha",
        "  - title: Rest",
        "    contents:",
        "      - beta",
        "      - '%+%'"
    ))
    fn_man <- published_pages(dir)

    labels <- sub("^man/", "", fn_man)
    out <- .sidebar_man_contents(fn_man, labels, src_dir = dir)

    expect_identical(out[[1]]$text, "alpha.qmd")
    expect_null(out[[1]]$section)
    expect_identical(out[[2]]$section, "Rest")
})

test_that("a section of only unrendered topics is skipped, not left empty", {
    dir <- local_sidebar_package(c(
        "reference:",
        "  - title: Core",
        "    contents:",
        "      - alpha",
        "  - title: Failed",
        "    contents:",
        "      - beta"
    ))
    # `beta`'s page failed to render, so it is documented but not published.
    fn_man <- setdiff(published_pages(dir), "man/beta.qmd")

    labels <- sub("^man/", "", fn_man)
    out <- .sidebar_man_contents(fn_man, labels, src_dir = dir)

    expect_identical(
        vapply(out, function(x) x$section, character(1)),
        c("Core", "Other")
    )
    expect_false(any(grepl("beta", flatten_sidebar(out))))
})

test_that("selectors group topics the same way they do on the index page", {
    dir <- local_sidebar_package(c(
        "reference:",
        "  - title: Greek",
        "    contents:",
        "      - starts_with('al')",
        "      - starts_with('be')"
    ))
    fn_man <- published_pages(dir)

    labels <- sub("^man/", "", fn_man)
    out <- .sidebar_man_contents(fn_man, labels, src_dir = dir)

    expect_identical(
        flatten_sidebar(out),
        c(
            "Greek > alpha.qmd",
            "Greek > beta.qmd",
            "Other > grapes-plus-grapes.qmd"
        )
    )
})

test_that("sidebar labels reach the entries inside a group", {
    dir <- local_sidebar_package(c(
        "sidebar_labels: name-and-title",
        "reference:",
        "  - title: Core",
        "    contents:",
        "      - alpha"
    ))
    fn_man <- published_pages(dir)
    labels <- .sidebar_labels(
        sub("\\.qmd$", "", basename(fn_man)),
        src_dir = dir
    )

    out <- .sidebar_man_contents(fn_man, labels, src_dir = dir)

    expect_identical(flatten_sidebar(out)[1], "Core > alpha(): First thing")
})
