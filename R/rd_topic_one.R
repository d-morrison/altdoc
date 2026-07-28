# Extract the reference-index metadata of a single .Rd file. Returns NULL when
# the file cannot be parsed, so that one malformed .Rd does not abort the whole
# reference index.
.rd_topic_one <- function(file, macros = NULL) {
    rd <- tryCatch(
        if (is.null(macros)) {
            tools::parse_Rd(file)
        } else {
            tools::parse_Rd(file, macros = macros)
        },
        error = function(e) NULL
    )
    if (is.null(rd)) {
        cli::cli_alert_warning(
            "Could not parse {.file {file}}; skipping it in the reference index."
        )
        return(NULL)
    }

    name <- .rd_tag_values(rd, "\\name")
    # An .Rd file without a \name{} carries no topic to label a row with.
    if (length(name) == 0) {
        return(NULL)
    }
    name <- name[1]

    alias <- .rd_tag_values(rd, "\\alias")
    if (length(alias) == 0) {
        alias <- name
    }

    keywords <- .rd_tag_values(rd, "\\keyword")

    list(
        name = name,
        file = fs::path_ext_remove(basename(file)),
        title = .rd_title(rd),
        alias = alias,
        keywords = keywords,
        concepts = .rd_tag_values(rd, "\\concept"),
        internal = "internal" %in% keywords,
        is_fun = .rd_is_function(rd, name)
    )
}
