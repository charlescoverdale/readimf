# Construct an imf_tbl: a data frame carrying IMF provenance attributes.
.new_imf_tbl <- function(x, dataflow, agency, source = NULL, vintage = NULL) {
  attr(x, "imf_dataflow")  <- dataflow
  attr(x, "imf_agency")    <- agency
  attr(x, "imf_source")    <- source
  attr(x, "imf_vintage")   <- vintage
  attr(x, "imf_retrieved") <- format(Sys.time(), tz = "UTC", usetz = TRUE)
  class(x) <- c("imf_tbl", "data.frame")
  x
}

#' Print an IMF data table
#'
#' @param x An `imf_tbl`, as returned by [imf_weo()].
#' @param n Number of rows to print.
#' @param ... Unused, for S3 compatibility.
#' @return `x`, invisibly.
#' @export
print.imf_tbl <- function(x, n = 10L, ...) {
  title <- sprintf("IMF data: %s/%s", attr(x, "imf_agency"), attr(x, "imf_dataflow"))
  vint <- attr(x, "imf_vintage")
  if (!is.null(vint) && !identical(vint, "latest")) {
    title <- sprintf("%s (vintage %s)", title, vint)
  }
  cli::cli_text("{.strong {title}}")

  bits <- sprintf("%d row%s", nrow(x), if (nrow(x) == 1L) "" else "s")
  if ("country" %in% names(x)) {
    ne <- length(unique(x$country))
    bits <- paste0(bits, sprintf(", %d econom%s", ne, if (ne == 1L) "y" else "ies"))
  }
  if ("period" %in% names(x) && nrow(x) > 0L) {
    rng <- range(x$period, na.rm = TRUE)
    bits <- paste0(bits, sprintf(", %s to %s", rng[1L], rng[2L]))
  }
  cli::cli_text("{.emph {bits}}")

  print(utils::head(as.data.frame(x), n))
  if (nrow(x) > n) cli::cli_text("{.emph ... and {nrow(x) - n} more rows}")
  invisible(x)
}
