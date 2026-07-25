local_labels_package <- function(..., env = parent.frame()) {
    dir <- withr::local_tempdir(.local_envir = env)
    fs::dir_copy(
        test_path("examples/testpkg.altdoc/man"),
        fs::path_join(c(dir, "man"))
    )
    settings <- c(...)
    if (length(settings) > 0) {
        fs::dir_create(fs::path_join(c(dir, "altdoc")))
        writeLines(settings, fs::path_join(c(dir, "altdoc", "reference.yml")))
    }
    dir
}

# Helper function to build a throwaway package documenting a single topic
# whose title is `title`, with the sidebar labels opted in. Both a source
# `man/*.Rd` (which supplies the title) and a rendered `docs/man/*.md` (which
# the generators list) are needed.
local_titled_package <- function(title, env = parent.frame()) {
    dir <- withr::local_tempdir(.local_envir = env)
    fs::dir_create(fs::path_join(c(dir, "man")))
    writeLines(
        c(
            "\\name{f}",
            "\\alias{f}",
            sprintf("\\title{%s}", title),
            "\\usage{f(x)}",
            "\\description{d}"
        ),
        fs::path_join(c(dir, "man", "f.Rd"))
    )
    fs::dir_create(fs::path_join(c(dir, "docs", "man")))
    writeLines("page", fs::path_join(c(dir, "docs", "man", "f.md")))
    fs::dir_create(fs::path_join(c(dir, "altdoc")))
    writeLines(
        "sidebar_labels: name-and-title",
        fs::path_join(c(dir, "altdoc", "reference.yml"))
    )
    dir
}

test_that(".sidebar_labels returns bare names by default", {
    dir <- local_labels_package()
    expect_identical(
        .sidebar_labels(c("hello_base", "hello_r6"), src_dir = dir),
        c("hello_base", "hello_r6")
    )
})

test_that(".sidebar_labels returns bare names when opted out explicitly", {
    dir <- local_labels_package("sidebar_labels: name")
    expect_identical(
        .sidebar_labels("hello_base", src_dir = dir),
        "hello_base"
    )
})

test_that(".sidebar_labels appends the Rd title when opted in", {
    dir <- local_labels_package("sidebar_labels: name-and-title")
    expect_identical(
        .sidebar_labels("hello_base", src_dir = dir),
        "hello_base(): Base function"
    )
})

test_that(".sidebar_labels only parenthesizes callable topics", {
    # hello_r6 documents an R6 generator, not a function, so it takes no `()`
    # --- the same rule the reference index applies.
    dir <- local_labels_package("sidebar_labels: name-and-title")
    expect_false(grepl(
        "hello_r6()",
        .sidebar_labels("hello_r6", src_dir = dir),
        fixed = TRUE
    ))
})

test_that(".sidebar_labels keeps the bare name for a topic with no .Rd", {
    # The page is still on the site, so it needs a usable label.
    dir <- local_labels_package("sidebar_labels: name-and-title")
    expect_identical(
        .sidebar_labels("not_a_topic", src_dir = dir),
        "not_a_topic"
    )
})

test_that(".sidebar_labels truncates the title but never the name", {
    dir <- local_labels_package(
        "sidebar_labels: name-and-title",
        "sidebar_label_width: 12"
    )
    out <- .sidebar_labels("hello_r6", src_dir = dir)
    expect_match(out, "^hello_r6: ")
    expect_match(out, "\\.\\.\\.$")
})

test_that(".sidebar_labels handles an empty topic vector", {
    dir <- local_labels_package("sidebar_labels: name-and-title")
    expect_identical(.sidebar_labels(character(0), src_dir = dir), character(0))
})

test_that(".truncate_label caps the total length, ellipsis included", {
    expect_identical(nchar(.truncate_label(strrep("a", 100), width = 20)), 20L)
    expect_identical(.truncate_label("short", width = 20), "short")
    expect_identical(.truncate_label(NA_character_, width = 20), NA_character_)
    expect_identical(.truncate_label(character(0), width = 20), character(0))
})

test_that("docsify escapes a title that would break the sidebar link", {
    # A topic name can never hold a square bracket, but an .Rd title can, and
    # an unescaped one closes the link text early.
    dir <- local_titled_package("Do not use R6 [beta]")
    out <- .sidebar_man_docsify(c("- Reference", "$ALTDOC_MAN_BLOCK"), dir)
    expect_identical(
        grep("man/f", out, value = TRUE),
        "  - [f(): Do not use R6 \\[beta\\]](man/f)"
    )
})

test_that("docute escapes a title that would break the sidebar entry", {
    # docute embeds the label in a single-quoted JavaScript string.
    dir <- local_titled_package("Don't use R6")
    out <- .sidebar_man_docute("$ALTDOC_MAN_BLOCK", dir)
    expect_identical(
        out,
        "{title: 'f(): Don\\'t use R6', link: '/man/f.md'}"
    )
})

test_that("reference.yml rejects an unknown sidebar_labels value", {
    dir <- local_labels_package("sidebar_labels: bogus")
    expect_error(.reference_settings(dir), "sidebar_labels")
})

test_that("reference.yml rejects a sidebar_labels that is not a single string", {
    # Either shape would otherwise slip past the value check and then silently
    # fail to match the opt-in. A one-element sequence is not among them: yaml
    # collapses it to a plain string, so it behaves exactly like the scalar.
    dir <- local_labels_package("sidebar_labels: [name, name-and-title]")
    expect_error(.reference_settings(dir), "sidebar_labels")

    dir <- local_labels_package("sidebar_labels:", "  nested: name")
    expect_error(.reference_settings(dir), "sidebar_labels")
})

test_that("reference.yml rejects a sidebar_label_width with no room for the ellipsis", {
    dir <- local_labels_package(
        "sidebar_labels: name-and-title",
        "sidebar_label_width: 2"
    )
    expect_error(.reference_settings(dir), "sidebar_label_width")
})

test_that("reference.yml rejects a fractional sidebar_label_width", {
    # `substr()` would truncate it, so 4.5 would quietly behave as 4.
    dir <- local_labels_package(
        "sidebar_labels: name-and-title",
        "sidebar_label_width: 4.5"
    )
    expect_error(.reference_settings(dir), "whole number")
})

test_that("reference.yml warns that sidebar_label_width alone does nothing", {
    dir <- local_labels_package("sidebar_label_width: 60")
    expect_warning(.reference_settings(dir), "no effect")
})

test_that("reference.yml does not warn when the width accompanies the opt-in", {
    dir <- local_labels_package(
        "sidebar_labels: name-and-title",
        "sidebar_label_width: 60"
    )
    expect_no_warning(.reference_settings(dir))
})
