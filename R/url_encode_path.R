# Percent-encode the characters in a repository-relative path that would
# otherwise change what an `href` means.
#
# A source path is data. roxygen2's `@backref` takes any path, and a filename
# may legitimately hold a character that a URL reads as structure rather than
# as content: `#` starts a fragment, `?` starts a query, and a bare `%` is the
# start of an escape. Left alone, `src/model#v2.cpp` reaches the forge as
# `src/model`.
#
# `/` is deliberately left alone, since it is the path separator here rather
# than content. `%` is encoded first, so an encoding this function introduces
# is not encoded a second time.
#
# Encoding `\` closes a second hole at the same time: the encoded string is
# what gets interpolated into a regex replacement, and a backslash there would
# read as a backreference.
.url_encode_path <- function(path) {
    replacements <- c(
        "%" = "%25",
        "\\" = "%5C",
        "#" = "%23",
        "?" = "%3F",
        " " = "%20",
        "\"" = "%22",
        "&" = "%26",
        "<" = "%3C",
        ">" = "%3E"
    )

    for (chr in names(replacements)) {
        path <- gsub(chr, replacements[[chr]], path, fixed = TRUE)
    }

    path
}
