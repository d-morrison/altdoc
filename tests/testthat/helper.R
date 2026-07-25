library(fs)
library(usethis)
library(withr)

### Taken from {usethis} (file "R/project.R")

proj <- new.env(parent = emptyenv())

proj_get_ <- function() proj$cur

### Taken from {usethis} (file "tests/testthat/helper.R")

create_local_package <- function(
    dir = fs::file_temp(pattern = "testpkg"),
    env = parent.frame(),
    rstudio = TRUE
) {
    create_local_thing(dir, env, rstudio, "package")
}

create_local_project <- function(
    dir = fs::file_temp(pattern = "testproj"),
    env = parent.frame(),
    rstudio = FALSE
) {
    create_local_thing(dir, env, rstudio, "project")
}

create_local_thing <- function(
    dir = fs::file_temp(pattern = pattern),
    env = parent.frame(),
    rstudio = FALSE,
    thing = c("package", "project")
) {
    thing <- match.arg(thing)
    if (fs::dir_exists(dir)) {
        ui_stop("Target {ui_code('dir')} {.file {dir}} already exists.")
    }

    old_project <- proj_get_() # this could be `NULL`, i.e. no active project
    old_wd <- getwd() # not necessarily same as `old_project`

    withr::defer(
        {
            try(fs::dir_delete(dir))
        },
        envir = env
    )
    usethis::ui_silence(
        switch(
            thing,
            package = usethis::create_package(
                dir,
                rstudio = rstudio,
                open = FALSE,
                check_name = FALSE
            ),
            project = usethis::create_project(
                dir,
                rstudio = rstudio,
                open = FALSE
            )
        )
    )

    withr::defer(usethis::proj_set(old_project, force = TRUE), envir = env)
    usethis::proj_set(dir)

    # flir-ignore-start
    withr::defer(
        {
            setwd(old_wd)
        },
        envir = env
    )
    setwd(usethis::proj_get())
    # flir-ignore-end

    invisible(usethis::proj_get())
}

# Helper function to setup test package from examples
setup_example_package <- function(example_name, env = parent.frame()) {
    path_to_example_pkg <- fs::path_abs(
        test_path(paste0("examples/", example_name))
    )
    create_local_project(env = env)
    fs::dir_delete("R")
    fs::dir_copy(path_to_example_pkg, ".")
    all_files <- list.files(example_name, full.names = TRUE)
    for (file_path in all_files) {
        fs::file_move(file_path, ".")
    }
    fs::dir_delete(example_name)
}

# Helper function to parse an .Rd file written inline in a test
rd_from_text <- function(...) {
    fn <- fs::file_temp(ext = "Rd")
    writeLines(c(...), fn)
    tools::parse_Rd(fn)
}

# Helper function to build a throwaway package with an altdoc/reference.yml
local_reference_package <- function(..., env = parent.frame()) {
    dir <- withr::local_tempdir(.local_envir = env)
    fs::dir_copy(
        test_path("examples/testpkg.altdoc/man"),
        fs::path_join(c(dir, "man"))
    )
    fs::dir_create(fs::path_join(c(dir, "altdoc")))
    writeLines(c(...), fs::path_join(c(dir, "altdoc", "reference.yml")))
    dir
}

# Helper function to report which topics a `contents:` list selects
selected_names <- function(contents, topics) {
    topics$name[.select_topics(contents, topics)]
}
