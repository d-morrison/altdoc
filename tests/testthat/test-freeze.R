test_that("comparing hashes works", {
    source_file <- tempfile()
    fs::file_copy(test_path("examples/examples-man/between.Rd"), source_file)
    hashes <- digest::digest(.readlines(source_file))
    names(hashes) <- source_file
    expect_true(.is_frozen(source_file, source_file, hashes))

    other_source_file <- test_path("examples/examples-man/between.md")
    expect_false(.is_frozen(other_source_file, other_source_file, hashes))

    # modified file doesn't have the same hash
    mod <- c(.readlines(source_file), "abc")
    cat(mod, file = source_file)
    expect_false(.is_frozen(source_file, source_file, hashes))
})

test_that(".is_frozen is FALSE if files don't exist", {
    source_file <- tempfile()
    fs::file_copy(test_path("examples/examples-man/between.Rd"), source_file)
    hashes <- digest::digest(.readlines(source_file))
    names(hashes) <- source_file
    expect_false(.is_frozen("foobar", "foobar", hashes))
})

test_that("quarto: freeze skips man pages when unchanged and cleans up stale .qmds", {
    skip_on_cran()
    skip_if(!.quarto_is_installed())

    create_local_package()
    fs::dir_create("man")
    cat(
        "\\name{hi}\n\\title{hi}\n\\usage{\nhi()\n}\n\\description{hi}\n",
        file = "man/hi.Rd"
    )
    cat(
        "\\name{ho}\n\\title{ho}\n\\usage{\nho()\n}\n\\description{ho}\n",
        file = "man/ho.Rd"
    )

    setup_docs("quarto_website")

    # First run
    render_docs(freeze = TRUE, verbose = FALSE)

    expect_true(fs::file_exists("_quarto/man/ho.qmd"))
    expect_true(fs::file_exists("altdoc/freeze.rds"))

    mtime1 <- fs::file_info("_quarto/man/hi.qmd")$modification_time

    # Delete one of the .Rd files to check that cleanup works
    fs::file_delete("man/ho.Rd")

    # Second run
    Sys.sleep(1.1)
    out <- capture_messages(render_docs(freeze = TRUE, verbose = FALSE))

    # Check that stale files are removed
    expect_false(fs::file_exists("_quarto/man/ho.qmd"))

    # Check that re-generation was skipped for unchanged man page
    mtime2 <- fs::file_info("_quarto/man/hi.qmd")$modification_time
    expect_equal(mtime1, mtime2)

    expect_match(
        paste(out, collapse = "\n"),
        "1 .Rd files skipped because they didn't change."
    )
})
