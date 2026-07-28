# The topics an index page actually lists.
#
# Internal topics are excluded because they document things a caller is not
# meant to reach for: listing them on the reference index sends a reader to a
# page about a helper, and listing them in `llms.txt` invites an agent to
# suggest one.
#
# Shared by the places that have to agree on that subset: `.llms_txt()` builds
# its entries from it, and `.import_llms_txt()` and `.import_reference()` both
# use it to report how many entries they wrote -- `.import_llms_txt()` also to
# decide whether there is anything to write at all. Applying the rule in only
# some of those places is how a package whose topics are all internal ends up
# with a file carrying no entries, or is told it published more topics than
# the page lists.
.listed_topics <- function(topics) {
    topics[!topics$internal, , drop = FALSE]
}
