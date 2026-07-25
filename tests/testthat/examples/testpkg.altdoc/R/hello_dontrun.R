#' Mixed runnable and non-runnable examples
#'
#' @return Some value
#' @export
#'
#' @examples
#' hello_dontrun()
#'
#' \dontrun{
#' stop("this must never be evaluated")
#' }
#'
#' hello_dontrun()
#'
#' \donttest{
#' Sys.sleep(1000)
#' }
hello_dontrun <- function() {
    print("Hello, world!")
}
