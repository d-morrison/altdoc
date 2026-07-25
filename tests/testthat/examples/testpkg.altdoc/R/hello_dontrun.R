#' Mixed runnable and non-runnable examples
#'
#' @param x A parameter
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
hello_dontrun <- function(x = 2) {
    print("Hello, world!")
}
