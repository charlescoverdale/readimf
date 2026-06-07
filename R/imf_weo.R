#' Download World Economic Outlook data
#'
#' @description
#' Fetch series from the IMF World Economic Outlook (WEO), the Fund's flagship
#' forecast database. The WEO is openly available, so no API key is required.
#'
#' @param indicator Character vector of WEO indicator codes, for example
#'   `"NGDP_RPCH"` (real GDP growth), `"NGDPD"` (GDP in US dollars) or
#'   `"PCPIPCH"` (inflation). `NULL` (the default) returns every indicator.
#' @param country Character vector of ISO 3-letter country codes, for example
#'   `c("GBR", "USA")`. `NULL` (the default) returns every economy.
#' @param start,end Optional first and last year to keep, for example `2000`
#'   and `2024`.
#' @param vintage Either `"latest"` (the current WEO release, the default) or a
#'   tag of the form `"YYYY-MM"` such as `"2025-10"` to request a specific
#'   historical release for forecast evaluation.
#'
#' @return An object of class `imf_tbl` (a data frame) with columns `country`,
#'   `indicator`, `freq`, `period` and `value`, carrying provenance attributes.
#'
#' @examples
#' \donttest{
#' imf_weo("NGDP_RPCH", country = c("GBR", "USA"), start = 2015, end = 2024)
#' }
#' @export
imf_weo <- function(indicator = NULL, country = NULL,
                    start = NULL, end = NULL, vintage = "latest") {
  flow <- .imf_weo_flow(vintage)
  key  <- .imf_key(country, indicator, "A")
  raw  <- .imf_fetch(agency = "IMF.RES", flow = flow, key = key,
                     api_key = .imf_api_key())
  out  <- .imf_tidy(raw)

  if (!is.null(start)) out <- out[out$period >= start, , drop = FALSE]
  if (!is.null(end))   out <- out[out$period <= end, , drop = FALSE]
  rownames(out) <- NULL

  .new_imf_tbl(out, dataflow = flow, agency = "IMF.RES",
               source = attr(raw, "imf_url"), vintage = vintage)
}

# Resolve a vintage tag to a WEO data flow id.
.imf_weo_flow <- function(vintage = "latest") {
  if (is.null(vintage) || identical(vintage, "latest")) return("WEO")
  if (!grepl("^[0-9]{4}-[0-9]{2}$", vintage)) {
    cli::cli_abort(c(
      "{.arg vintage} must be {.val latest} or a tag like {.val 2025-10}.",
      "x" = "You supplied {.val {vintage}}."
    ))
  }
  year  <- substr(vintage, 1L, 4L)
  month <- toupper(month.abb[as.integer(substr(vintage, 6L, 7L))])
  sprintf("WEO_%s_%s_VINTAGE", year, month)
}
