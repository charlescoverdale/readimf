#' Fetch a legacy IFS series from its new home
#'
#' @description
#' International Financial Statistics (IFS) was retired when the IMF moved to
#' the 'SDMX' 3.0 portal. Its content was split across several thematic data
#' flows (consumer prices, exchange rates, monetary statistics and others) with
#' no official code crosswalk, which broke every workflow built on the old IFS
#' series codes. `imf_ifs()` accepts a legacy IFS indicator code and routes the
#' request to the correct new data flow and key.
#'
#' Use [imf_ifs_map()] to see which legacy series are supported and where each
#' one now lives. Country coverage in the new data flows varies, especially for
#' interest rates; if a country returns nothing, try another.
#'
#' @param indicator A legacy IFS indicator code, for example `"PCPI_IX"`
#'   (consumer price index) or `"ENDA_XDC_USD_RATE"` (exchange rate per USD).
#' @param country Character vector of ISO 3-letter country codes, for example
#'   `c("GBR", "USA")`. Required: the underlying data flows do not serve
#'   wildcard country queries without an API key.
#' @param freq Frequency code (`"A"`, `"Q"` or `"M"`). Defaults to the series'
#'   usual frequency.
#' @param start,end Optional first and last year to keep.
#'
#' @return An object of class `imf_tbl` (a data frame). The originating IFS code
#'   is retained in the `imf_ifs_code` attribute.
#'
#' @examples
#' \donttest{
#' # UK consumer price index, the series formerly known as IFS PCPI_IX
#' imf_ifs("PCPI_IX", country = "GBR", start = 2015)
#' }
#' @seealso [imf_ifs_map()], [imf_data()]
#' @export
imf_ifs <- function(indicator, country = NULL, freq = NULL,
                    start = NULL, end = NULL) {
  row <- ifs_crosswalk[ifs_crosswalk$ifs_code == indicator, , drop = FALSE]
  if (nrow(row) == 0L) {
    cli::cli_abort(c(
      "Unknown IFS indicator {.val {indicator}}.",
      "i" = "See {.fn imf_ifs_map} for the supported legacy IFS series."
    ))
  }
  row <- row[1L, ]

  if (is.null(country) || !any(nzchar(country))) {
    cli::cli_abort(c(
      "{.arg country} is required for IFS series.",
      "i" = "The new IMF data flows do not serve wildcard country queries without an API key.",
      "i" = "Supply an ISO 3-letter code, for example {.code country = \"GBR\"}."
    ))
  }

  f <- if (is.null(freq)) row$default_freq else freq
  key <- .imf_ifs_build_key(row$key_template, country, f)

  out <- tryCatch(
    imf_data(dataflow = row$dataflow, key = key, agency = row$agency,
             start = start, end = end),
    error = function(e) {
      if (grepl("no observations", conditionMessage(e), fixed = TRUE)) {
        cli::cli_abort(c(
          "No data for IFS series {.val {indicator}} and country {.val {country}}.",
          "i" = "It now lives in data flow {.val {row$dataflow}}, where country coverage varies.",
          "i" = "Try another country (for example {.val USA}) or frequency."
        ))
      }
      stop(e)
    }
  )
  attr(out, "imf_ifs_code") <- indicator
  out
}

# Substitute the {country} and {freq} placeholders in a key template.
.imf_ifs_build_key <- function(template, country, freq) {
  k <- gsub("{country}", paste(country, collapse = "+"), template, fixed = TRUE)
  gsub("{freq}", freq, k, fixed = TRUE)
}

#' Show the IFS migration crosswalk
#'
#' Reveal which new data flow and key each supported legacy IFS indicator maps
#' to. This is the documentation behind [imf_ifs()] and a migration aid in its
#' own right: it shows where a retired IFS series now lives without fetching any
#' data.
#'
#' @param indicator Optional vector of legacy IFS codes to filter to. With no
#'   argument the whole crosswalk is returned.
#' @return A data frame with columns `ifs_code`, `description`, `agency`,
#'   `dataflow`, `key_template` and `default_freq`.
#' @examples
#' imf_ifs_map()
#' imf_ifs_map("PCPI_IX")
#' @seealso [imf_ifs()]
#' @export
imf_ifs_map <- function(indicator = NULL) {
  cw <- ifs_crosswalk
  if (!is.null(indicator)) {
    cw <- cw[cw$ifs_code %in% indicator, , drop = FALSE]
    if (nrow(cw) == 0L) {
      cli::cli_abort("No IFS mapping found for {.val {indicator}}.")
    }
  }
  rownames(cw) <- NULL
  cw[, c("ifs_code", "description", "agency", "dataflow", "key_template", "default_freq")]
}
