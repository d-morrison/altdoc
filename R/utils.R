# https://github.com/ropenscilabs/r2readthedocs/blob/main/R/utils.R
.convert_path <- function(path = ".") {
    path <- fs::path_abs(path)
    .check_is_package(path = path)
    path <- normalizePath(path)
    return(path)
}

.dir_is_package <- function(path) {
    fs::file_exists(fs::path_abs("DESCRIPTION", start = path))
}

.is_windows <- function() {
    .Platform$OS.type == "windows"
}

.venv_exists <- function(path = ".") {
    venv_path <- Sys.getenv("ALTDOC_VENV")
    if (identical(venv_path, "")) {
        venv_path <- fs::path_abs(".venv_altdoc", start = path)
    }
    fs::dir_exists(venv_path)
}

.folder_is_empty <- function(x) {
    length(list.files(x)) == 0
}

.pkg_name <- function(path) {
    desc::desc_get_field("Package", default = NULL, file = path)
}

.gh_url <- function(path) {
    .gh_urls <- c(
        desc::desc_get_urls(path),
        desc::desc_get_field("BugReports", default = NULL, file = path)
    )

    if (length(.gh_urls) == 0) {
        return(NULL)
    }

    .gh_url <- .gh_urls[grep("github.com", .gh_urls)]
    .gh_url <- gsub("/issues", "", .gh_url, fixed = TRUE)
    if (length(.gh_url) == 0) {
        .gh_url <- .gh_urls[grep("github.io", .gh_urls)]
        .gh_url <- gsub(".github.io", "", .gh_url)
        .gh_url <- gsub(
            "https://",
            "https://github.com/",
            .gh_url,
            fixed = TRUE
        )
    }
    .gh_url <- gsub(" ", "", .gh_url, fixed = TRUE)
    .gh_url <- gsub("#.*", "", .gh_url)
    .gh_url <- unique(.gh_url)

    if (length(.gh_url) == 0) {
        return(NULL)
    }

    return(.gh_url)
}

# Get the tool that was used
.doc_type <- function(path = ".") {
    fn <- fs::path_join(c(path, "altdoc", "mkdocs.yml"))
    mkdocs <- fs::file_exists(fn)

    fn <- fs::path_join(c(path, "altdoc", "docsify.md"))
    docsify <- fs::file_exists(fn)

    fn <- fs::path_join(c(path, "altdoc", "docute.html"))
    docute <- fs::file_exists(fn)

    fn <- fs::path_join(c(path, "altdoc", "quarto_website.yml"))
    quarto_website <- fs::file_exists(fn)

    if (sum(c(mkdocs, docsify, docute, quarto_website)) == 0) {
        cli::cli_abort(
            "No documentation tool detected. Please run the {.code setup_docs()} function.",
            .envir = parent.frame(sys.nframe() - 1)
        )
    } else if (sum(c(mkdocs, docsify, docute, quarto_website)) > 1) {
        cli::cli_abort(
            "Settings detected for multiple output formats in `altdoc/`. Please remove all but one or run `setup_docs()` with `overwrite=TRUE`.",
            .envir = parent.frame(sys.nframe() - 1)
        )
    }

    if (mkdocs) {
        return("mkdocs")
    }
    if (docsify) {
        return("docsify")
    }
    if (docute) {
        return("docute")
    }
    if (quarto_website) {
        return("quarto_website")
    }

    return(NULL)
}

# Get the path for files
.doc_path <- function(path = ".") {
    return(fs::path_abs("docs", start = path))
}

# Detect how licence files is called: "LICENSE" or "LICENCE"
.which_license <- function(path = ".") {
    x <- list.files(path = path, pattern = "\\.md$")
    license <- x[grep("license", x, ignore.case = TRUE)]
    licence <- x[grep("licence", x, ignore.case = TRUE)]
    if (length(license) == 1) {
        return(license)
    } else if (length(licence) == 1) {
        return(licence)
    } else {
        return(NULL)
    }
}

.altdoc_version <- function() {
    as.character(utils::packageVersion("altdoc"))
}

.readlines <- function(x) {
    readLines(x, warn = FALSE)
}

# TRUE for a URL that points at a code-hosting forge rather than a
# documentation site. A package whose only `URL:` is its repository has no
# site, and treating the repo as one produces links that 404 -- e.g.
# `https://github.com/user/pkg/man/foo.md`.
.is_forge_url <- function(x) {
    grepl("github\\.com|gitlab\\.com|codeberg\\.org", x)
}

.add_pkgdown <- function(path = ".") {
    if (!isTRUE(.dir_is_package(path))) {
        stop(
            ".add_pkgdown() must be run from the root of a package.",
            call. = FALSE
        )
    }
    # `.description_site_url()` returns NULL when every `URL:` is a code
    # repository, so `urls:` is omitted rather than rooted at a forge. Appending
    # `/man` to a repository root yields a path that does not exist, and
    # `downlit` reads this block to autolink vignettes -- so a wrong value here
    # produces autolinks that 404, while a missing one makes it skip
    # autolinking. See #85.
    url <- .description_site_url(path)
    output_path <- fs::path_join(c(path, "altdoc/pkgdown.yml"))
    already_exists <- fs::file_exists(output_path)

    # Whether the file ends up declaring `urls:`, which is a different question
    # from whether `DESCRIPTION` named a site: an existing file can carry a
    # hand-written block that no `URL:` implies. The advice below is gated on
    # this rather than on `url`, so it is never printed at a file that already
    # has what it asks for.
    declares_urls <- FALSE

    if (already_exists) {
        # Refreshing `last_built` and the tool versions records what produced
        # the current render, so it is unconditional: it has nothing to do with
        # which `URL:` the package declares, and skipping it when there is no
        # site URL would leave the file describing a build that no longer
        # happened.
        yaml_content <- yaml::read_yaml(output_path)
        yaml_content[["altdoc"]] <- .altdoc_version()
        yaml_content[["pandoc"]] <- as.character(rmarkdown::pandoc_version())
        if (is.null(yaml_content[["pkgdown"]])) {
            yaml_content[["pkgdown"]] <- "2.1.3" # don't know if this actually matters
        }
        yaml_content["pkgdown_sha"] <- list(NULL)
        # https://stackoverflow.com/questions/29517896/current-time-in-iso-8601-format
        yaml_content[["last_built"]] <- strftime(
            as.POSIXlt(Sys.time(), "UTC"),
            "%Y-%m-%dT%H:%M:%S%z"
        )
        # A `urls:` block is only ever added, never overwritten. One already in
        # the file is the maintainer's, and it outranks anything derived from
        # `DESCRIPTION` -- this file is where a site served from somewhere other
        # than the first `URL:` entry gets recorded.
        if (is.null(yaml_content[["urls"]]) && !is.null(url)) {
            yaml_content[["urls"]] <- .pkgdown_urls(url)
        }
        declares_urls <- !is.null(yaml_content[["urls"]])
        cli::cli_alert_info("Updated altdoc/pkgdown.yml file.")
        yaml::write_yaml(yaml_content, output_path)
    } else if (!is.null(url)) {
        yaml_content <- list(
            altdoc = .altdoc_version(),
            pandoc = as.character(rmarkdown::pandoc_version()),
            pkgdown = "2.1.3", # don't know if this actually matters
            pkgdown_sha = NULL,

            # https://stackoverflow.com/questions/29517896/current-time-in-iso-8601-format
            last_built = strftime(
                as.POSIXlt(Sys.time(), "UTC"),
                "%Y-%m-%dT%H:%M:%S%z"
            ),
            urls = .pkgdown_urls(url)
        )
        declares_urls <- TRUE
        cli::cli_alert_info("Added altdoc/pkgdown.yml file.")
        yaml::write_yaml(yaml_content, output_path)
    }

    if (!declares_urls) {
        # Say so at render time. Otherwise the absence is silent, and the
        # maintainer of a forge-hosted package learns their `DESCRIPTION` needs
        # a site `URL:` only by following a missing autolink on the published
        # site -- or never. Not a warning: a package with no site is a valid
        # state, and the render itself is unaffected.
        cli::cli_alert_info(
            "No documentation site URL found in DESCRIPTION, so {.file altdoc/pkgdown.yml} declares no {.field urls}: {.pkg downlit} will not autolink function calls in vignettes. Add a site {.field URL} to DESCRIPTION to enable it; a code repository URL is not one."
        )
    }
}

# The `urls:` block `downlit` reads, rooted at a site URL. `/man` and
# `/vignettes` are pkgdown's conventional subdirectories for the two.
.pkgdown_urls <- function(url) {
    return(list(
        reference = paste0(url, "/man"),
        article = paste0(url, "/vignettes")
    ))
}

.add_rbuildignore <- function(x = "^docs$", path = ".") {
    if (!isTRUE(.dir_is_package(path))) {
        stop(
            ".add_rbuildignore() must be run from the root of a package.",
            call. = FALSE
        )
    }
    fn <- fs::path_join(c(path, ".Rbuildignore"))
    if (!fs::file_exists(fn)) {
        fs::file_create(fn)
    }
    tmp <- .readlines(fn)
    if (!x %in% tmp) {
        cli::cli_alert_info("Adding {x} to .Rbuildignore")
        tmp <- c(tmp, x)
        writeLines(tmp, fn)
    }
}

.add_gitignore <- function(x = "^docs$", path = ".") {
    if (!isTRUE(.dir_is_package(path))) {
        stop(
            ".add_gitignore() must be run from the root of a package.",
            call. = FALSE
        )
    }
    fn <- fs::path_join(c(path, ".gitignore"))
    if (!fs::file_exists(fn)) {
        fs::file_create(fn)
    }
    tmp <- .readlines(fn)
    if (!x %in% tmp) {
        cli::cli_alert_info("Adding {x} to .gitignore")
        tmp <- c(tmp, x)
        writeLines(tmp, fn)
    }
}

.has_preamble <- function(fn) {
    x <- .readlines(fn)
    first_non_empty <- x[which(!x == "")[1]]
    grepl("^---\\w*", first_non_empty)
}

# find the head branch of git repository
.find_head_branch <- function(path = ".") {
    if (!fs::file_exists(".git/HEAD")) {
        return(NULL)
    }
    branch <- .readlines(".git/HEAD")
    gsub("^ref: refs/heads/", "", branch)
}

.on_ci <- function() {
    isTRUE(as.logical(Sys.getenv("CI", "false")))
}

# Adapted from quarto::quarto_binary_sitrep() because we don't want the
# comparison with the RStudio quarto binary version.
.quarto_is_installed <- function() {
    !is.null(quarto::quarto_path())
}

.check_quarto_installed <- function() {
    if (!.quarto_is_installed()) {
        cli::cli_abort(
            c(
                "Quarto (the command-line tool) is not installed on your system.",
                "i" = "It is needed to render manual pages and vignettes.",
                "i" = "Install it from {.url https://quarto.org/docs/get-started}."
            )
        )
    }
}
