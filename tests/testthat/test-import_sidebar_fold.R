staged_lines <- function(dir) {
    quarto_dir <- fs::path_join(c(dir, "_quarto"))
    fs::dir_create(quarto_dir)
    name <- .import_sidebar_fold(src_dir = dir, tar_dir = quarto_dir)
    expect_identical(name, "sidebar-fold.html")
    .readlines(fs::path_join(c(quarto_dir, name)))
}

test_that(".sidebar_fold_default is FALSE without a settings file", {
    dir <- withr::local_tempdir()
    expect_false(.sidebar_fold_default(dir))
})

test_that(".sidebar_fold_default is FALSE when opted out explicitly", {
    dir <- local_reference_package("sidebar_fold: expanded")
    expect_false(.sidebar_fold_default(dir))
})

test_that(".sidebar_fold_default is TRUE when set to collapsed", {
    dir <- local_reference_package("sidebar_fold: collapsed")
    expect_true(.sidebar_fold_default(dir))
})

test_that("sidebar_fold is a known top-level key", {
    dir <- local_reference_package("sidebar_fold: collapsed")
    expect_identical(.reference_settings(dir)$sidebar_fold, "collapsed")
})

test_that("an unrecognized sidebar_fold value is an error", {
    dir <- local_reference_package("sidebar_fold: sometimes")
    expect_error(.reference_settings(dir), "sidebar_fold")
})

test_that("a non-string sidebar_fold value is an error", {
    dir <- local_reference_package("sidebar_fold: true")
    expect_error(.reference_settings(dir), "sidebar_fold")
})

test_that(".import_sidebar_fold leaves no placeholder behind", {
    dir <- local_reference_package("sidebar_fold: collapsed")
    expect_false(any(grepl("@ALTDOC_FOLD_DEFAULT@", staged_lines(dir))))
})

test_that(".import_sidebar_fold bakes in the collapsed default", {
    dir <- local_reference_package("sidebar_fold: collapsed")
    expect_true(any(grepl(
        "FOLDED_BY_DEFAULT = true;",
        staged_lines(dir),
        fixed = TRUE
    )))
})

test_that(".import_sidebar_fold defaults to an open sidebar", {
    dir <- withr::local_tempdir()
    expect_true(any(grepl(
        "FOLDED_BY_DEFAULT = false;",
        staged_lines(dir),
        fixed = TRUE
    )))
})

test_that("the staged partial carries the style as well as the script", {
    dir <- withr::local_tempdir()
    lines <- staged_lines(dir)
    # Both halves ship together so a site needs no stylesheet of its own; a
    # partial holding only the script would leave the button inert.
    expect_true(any(grepl("<style>", lines, fixed = TRUE)))
    expect_true(any(grepl("<script>", lines, fixed = TRUE)))
    expect_true(any(grepl("sidebar-folded", lines, fixed = TRUE)))
})

test_that("$ALTDOC_SIDEBAR_FOLD resolves for quarto_website", {
    dir <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(dir, "_quarto")))
    out <- .substitute_altdoc_variables(
        "    include-in-header: $ALTDOC_SIDEBAR_FOLD",
        path = dir,
        tool = "quarto_website"
    )
    expect_identical(out, "    include-in-header: sidebar-fold.html")
    expect_true(fs::file_exists(
        fs::path_join(c(dir, "_quarto", "sidebar-fold.html"))
    ))
})

test_that("$ALTDOC_SIDEBAR_FOLD drops the line for other generators", {
    dir <- withr::local_tempdir()
    out <- .substitute_altdoc_variables(
        c("keep me", "    include-in-header: $ALTDOC_SIDEBAR_FOLD"),
        path = dir,
        tool = "docsify"
    )
    expect_identical(out, "keep me")
})

test_that("nothing is staged for a site that does not use the variable", {
    dir <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(dir, "_quarto")))
    .substitute_altdoc_variables(
        "    include-in-header: header.html",
        path = dir,
        tool = "quarto_website"
    )
    expect_false(fs::file_exists(
        fs::path_join(c(dir, "_quarto", "sidebar-fold.html"))
    ))
})

test_that("ALTDOC_SIDEBAR_FOLD is a variable check_altdoc() knows", {
    # Without this the check reports the variable as unknown, which is the
    # failure mode it exists to distinguish from a missing source.
    expect_true("ALTDOC_SIDEBAR_FOLD" %in% .altdoc_variable_names())
})
