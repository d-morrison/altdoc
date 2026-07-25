test_that(".stage_external_includes() stages includes that escape the tree", {
    root <- withr::local_tempdir()

    # source tree: a shared macros file outside vignettes/, referenced via `..`
    fs::dir_create(fs::path_join(c(root, "macros")))
    writeLines("MACROS", fs::path_join(c(root, "macros", "macros.qmd")))

    # `_quarto/` tree as altdoc assembles it before rendering
    vig <- fs::path_join(c(root, "_quarto", "vignettes"))
    fs::dir_create(fs::path_join(c(vig, "articles")))
    writeLines(
        c(
            "{{< include ../macros/macros.qmd >}}",
            "{{< include articles/_local.qmd >}}"
        ),
        fs::path_join(c(vig, "methodology.qmd"))
    )
    # an in-tree include, already staged with its directory
    writeLines("LOCAL", fs::path_join(c(vig, "articles", "_local.qmd")))

    .stage_external_includes(
        src_dir = root,
        quarto_dir = fs::path_join(c(root, "_quarto"))
    )

    # the escaping include is copied to the path Quarto will resolve it to
    staged <- fs::path_join(c(root, "_quarto", "macros", "macros.qmd"))
    expect_true(fs::file_exists(staged))
    expect_identical(.readlines(staged), "MACROS")

    # the in-tree include is left where it already was, not re-staged elsewhere
    expect_false(
        fs::file_exists(fs::path_join(c(
            root,
            "_quarto",
            "articles",
            "_local.qmd"
        )))
    )
})

test_that(".stage_external_includes() follows nested includes recursively", {
    root <- withr::local_tempdir()

    fs::dir_create(fs::path_join(c(root, "macros")))
    # macros.qmd itself pulls in a sibling via an escaping include
    writeLines(
        "{{< include ../shared/defs.qmd >}}",
        fs::path_join(c(root, "macros", "macros.qmd"))
    )
    fs::dir_create(fs::path_join(c(root, "shared")))
    writeLines("DEFS", fs::path_join(c(root, "shared", "defs.qmd")))

    vig <- fs::path_join(c(root, "_quarto", "vignettes"))
    fs::dir_create(vig)
    writeLines(
        "{{< include ../macros/macros.qmd >}}",
        fs::path_join(c(vig, "methodology.qmd"))
    )

    .stage_external_includes(
        src_dir = root,
        quarto_dir = fs::path_join(c(root, "_quarto"))
    )

    expect_true(
        fs::file_exists(fs::path_join(c(
            root,
            "_quarto",
            "macros",
            "macros.qmd"
        )))
    )
    expect_true(
        fs::file_exists(fs::path_join(c(root, "_quarto", "shared", "defs.qmd")))
    )
})

test_that(".stage_external_includes() follows escaping includes nested in-tree", {
    root <- withr::local_tempdir()
    fs::dir_create(fs::path_join(c(root, "macros")))
    writeLines("MACROS", fs::path_join(c(root, "macros", "macros.qmd")))

    vig <- fs::path_join(c(root, "_quarto", "vignettes"))
    fs::dir_create(fs::path_join(c(vig, "articles")))
    writeLines(
        "{{< include ../../macros/macros.qmd >}}",
        fs::path_join(c(vig, "articles", "_local.qmd"))
    )
    writeLines(
        "{{< include articles/_local.qmd >}}",
        fs::path_join(c(vig, "methodology.qmd"))
    )

    .stage_external_includes(
        src_dir = root,
        quarto_dir = fs::path_join(c(root, "_quarto"))
    )

    expect_true(
        fs::file_exists(fs::path_join(c(
            root,
            "_quarto",
            "macros",
            "macros.qmd"
        )))
    )
})

test_that(".stage_external_includes() stages front-matter shortcode paths", {
    root <- withr::local_tempdir()

    # source tree: a Lua shortcode in a repo-root _extensions/, referenced
    # from a vignette's front matter rather than from an include
    ext <- fs::path_join(c(root, "_extensions", "d-morrison", "slidebreak"))
    fs::dir_create(ext)
    writeLines("-- filter", fs::path_join(c(ext, "slidebreak.lua")))

    vig <- fs::path_join(c(root, "_quarto", "vignettes"))
    fs::dir_create(vig)
    writeLines(
        c(
            "---",
            "title: Methodology",
            "shortcodes:",
            "  - ../_extensions/d-morrison/slidebreak/slidebreak.lua",
            "---",
            "",
            "Body text."
        ),
        fs::path_join(c(vig, "methodology.qmd"))
    )

    .stage_external_includes(
        src_dir = root,
        quarto_dir = fs::path_join(c(root, "_quarto"))
    )

    expect_true(
        fs::file_exists(fs::path_join(c(
            root,
            "_quarto",
            "_extensions",
            "d-morrison",
            "slidebreak",
            "slidebreak.lua"
        )))
    )
})

test_that(".stage_external_includes() stages filters and metadata-files too", {
    root <- withr::local_tempdir()

    fs::dir_create(fs::path_join(c(root, "shared")))
    writeLines("-- filter", fs::path_join(c(root, "shared", "anchors.lua")))
    writeLines("key: value", fs::path_join(c(root, "shared", "meta.yml")))

    vig <- fs::path_join(c(root, "_quarto", "vignettes"))
    fs::dir_create(vig)
    writeLines(
        c(
            "---",
            "filters:",
            "  - ../shared/anchors.lua",
            "  - quarto", # a built-in name, not a path: must be left alone
            "metadata-files:",
            "  - ../shared/meta.yml",
            "---"
        ),
        fs::path_join(c(vig, "article.qmd"))
    )

    .stage_external_includes(
        src_dir = root,
        quarto_dir = fs::path_join(c(root, "_quarto"))
    )

    expect_true(
        fs::file_exists(fs::path_join(c(
            root,
            "_quarto",
            "shared",
            "anchors.lua"
        )))
    )
    expect_true(
        fs::file_exists(fs::path_join(c(root, "_quarto", "shared", "meta.yml")))
    )
    # A bare extension name resolves to no file, so nothing is created for it.
    expect_false(fs::file_exists(fs::path_join(c(root, "_quarto", "quarto"))))
})

test_that(".front_matter_lines() reads only a leading, terminated block", {
    expect_equal(
        .front_matter_lines(c("---", "title: x", "---", "body")),
        "title: x"
    )
    # `...` is YAML's other document terminator, which Quarto accepts.
    expect_equal(
        .front_matter_lines(c("---", "title: x", "...", "body")),
        "title: x"
    )
    # Not front matter: the fence has to be the very first line.
    expect_equal(.front_matter_lines(c("body", "---", "title: x", "---")), character(0))
    # Unterminated, and empty, blocks yield nothing rather than erroring.
    expect_equal(.front_matter_lines(c("---", "title: x")), character(0))
    expect_equal(.front_matter_lines(c("---", "---")), character(0))
    expect_equal(.front_matter_lines(character(0)), character(0))
})

test_that(".front_matter_paths() ignores keys that are not path-valued", {
    lines <- c(
        "---",
        "title: Not a path",
        "bibliography: ../refs.bib",
        "shortcodes:",
        "  - ../a.lua",
        "---"
    )
    # `title:`/`bibliography:` are deliberately out of scope: Quarto resolves
    # the latter itself, and staging it here would be a behavior change beyond
    # the reported bug.
    expect_equal(.front_matter_paths(lines), "../a.lua")
})

test_that(".front_matter_paths() tolerates malformed front matter", {
    # Quarto reports the YAML error with better diagnostics than this pass
    # could, so staging simply finds nothing.
    expect_equal(
        .front_matter_paths(c("---", "shortcodes: [unclosed", "---")),
        character(0)
    )
    expect_equal(.front_matter_paths(c("no front matter here")), character(0))
})
