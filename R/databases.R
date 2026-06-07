# Shared fetch for the named database wrappers: call imf_data() and rephrase an
# empty result as a coverage message rather than the generic engine error.
.imf_fetch_named <- function(agency, dataflow, key, what, start = NULL, end = NULL) {
  tryCatch(
    imf_data(dataflow = dataflow, key = key, agency = agency, start = start, end = end),
    error = function(e) {
      if (grepl("no observations", conditionMessage(e), fixed = TRUE)) {
        cli::cli_abort(c(
          "No data returned for {what}.",
          "i" = "Coverage in data flow {.val {dataflow}} varies; check the country, partner, currency or frequency."
        ))
      }
      stop(e)
    }
  )
}

.imf_require <- function(value, name) {
  if (is.null(value) || !any(nzchar(value))) {
    cli::cli_abort("{.arg {name}} is required (supply an ISO 3-letter code).")
  }
}

#' Consumer prices
#'
#' Consumer price index or year-on-year inflation, from the IMF `CPI` data flow.
#'
#' @param country Character vector of ISO 3-letter country codes. Required.
#' @param measure `"index"` (the all-items index) or `"inflation"` (year-on-year
#'   percent change).
#' @param freq Frequency code (`"M"`, `"Q"` or `"A"`).
#' @param start,end Optional first and last year to keep.
#' @return An object of class `imf_tbl` (a data frame).
#' @examples
#' \donttest{
#' imf_cpi("GBR", measure = "inflation", start = 2015)
#' }
#' @seealso [imf_data()], [imf_ifs()]
#' @export
imf_cpi <- function(country, measure = c("index", "inflation"), freq = "M",
                    start = NULL, end = NULL) {
  measure <- match.arg(measure)
  .imf_require(country, "country")
  transform <- switch(measure, index = "IX", inflation = "YOY_PCH_PA_PT")
  key <- paste0(paste(country, collapse = "+"), ".CPI._T.", transform, ".", freq)
  .imf_fetch_named("IMF.STA", "CPI", key,
                   paste0("CPI ", measure, " for ", paste(country, collapse = ", ")),
                   start, end)
}

#' Bilateral goods trade (Direction of Trade)
#'
#' Goods exports or imports between a reporter and a partner economy, from the
#' IMF `IMTS` data flow (the successor to Direction of Trade Statistics).
#'
#' @param reporter ISO 3-letter code of the reporting economy. Only economies
#'   that report to the IMF appear here; many (including the UK) do not.
#' @param partner ISO 3-letter code of the partner (counterpart) economy.
#' @param flow `"exports"` (goods, FOB) or `"imports"` (goods, CIF), in US
#'   dollars.
#' @param freq Frequency code (`"M"`, `"Q"` or `"A"`).
#' @param start,end Optional first and last year to keep.
#' @return An object of class `imf_tbl` (a data frame).
#' @examples
#' \donttest{
#' # US goods exports to the UK
#' imf_dots("USA", "GBR", flow = "exports", start = 2020)
#' }
#' @seealso [imf_data()]
#' @export
imf_dots <- function(reporter, partner, flow = c("exports", "imports"),
                     freq = "M", start = NULL, end = NULL) {
  flow <- match.arg(flow)
  .imf_require(reporter, "reporter")
  .imf_require(partner, "partner")
  indicator <- switch(flow, exports = "XG_FOB_USD", imports = "MG_CIF_USD")
  key <- paste0(paste(reporter, collapse = "+"), ".", indicator, ".",
                paste(partner, collapse = "+"), ".", freq)
  .imf_fetch_named("IMF.STA", "IMTS", key,
                   paste0("goods ", flow, " from ", paste(reporter, collapse = ", "),
                          " to ", paste(partner, collapse = ", ")),
                   start, end)
}

#' Currency composition of official foreign exchange reserves (COFER)
#'
#' The share, or nominal value, of a reserve currency in allocated world foreign
#' exchange reserves, from the IMF `COFER` data flow. COFER is published only
#' for world and country-group aggregates, never individual economies.
#'
#' @param currency Reserve currency code: `"USD"`, `"EUR"`, `"JPY"`, `"GBP"`,
#'   `"CNY"` (or `"T"` for the total of allocated reserves).
#' @param measure `"share"` (percent of allocated reserves) or `"value"`
#'   (nominal US dollars).
#' @param group Aggregate code; `"G001"` (the World) by default.
#' @param freq Frequency code (`"Q"` or `"A"`).
#' @param start,end Optional first and last year to keep.
#' @return An object of class `imf_tbl` (a data frame).
#' @examples
#' \donttest{
#' # US dollar share of world allocated reserves
#' imf_cofer(currency = "USD", measure = "share")
#' }
#' @seealso [imf_data()]
#' @export
imf_cofer <- function(currency = "USD", measure = c("share", "value"),
                      group = "G001", freq = "Q", start = NULL, end = NULL) {
  measure <- match.arg(measure)
  fxr <- paste0("CI_", toupper(currency))
  transform <- switch(measure, share = "SHRO_PT", value = "NV_USD")
  key <- paste0(group, ".AFXRA.", fxr, ".", transform, ".", freq)
  .imf_fetch_named("IMF.STA", "COFER", key,
                   paste0("COFER ", measure, " for ", toupper(currency)),
                   start, end)
}

#' Primary commodity prices
#'
#' Commodity price levels or indices, from the IMF `PCPS` data flow (Primary
#' Commodity Price System). Prices are global, so no country is required.
#'
#' @param indicator A PCPS commodity code, for example `"PALLFNF"` (all
#'   non-fuel commodities index), `"POILWTI"` (WTI crude), `"POILBRE"` (Brent
#'   crude) or `"POILAPSP"` (average crude).
#' @param measure `"index"` (2016 = 100), `"usd"` (US dollars, for price
#'   series), `"pch_year"` (year-on-year percent change) or `"pch"` (period
#'   percent change).
#' @param freq Frequency code (`"M"`, `"Q"` or `"A"`).
#' @param start,end Optional first and last year to keep.
#' @return An object of class `imf_tbl` (a data frame).
#' @examples
#' \donttest{
#' imf_commodity("POILWTI", measure = "usd", start = 2015)
#' imf_commodity("PALLFNF", measure = "index")
#' }
#' @seealso [imf_data()]
#' @export
imf_commodity <- function(indicator = "PALLFNF",
                          measure = c("index", "usd", "pch_year", "pch"),
                          freq = "M", start = NULL, end = NULL) {
  measure <- match.arg(measure)
  transform <- switch(measure, index = "INDEX", usd = "USD",
                      pch_year = "INDEX_PCHY", pch = "INDEX_PCH")
  key <- paste0("G001.", paste(indicator, collapse = "+"), ".", transform, ".", freq)
  .imf_fetch_named("IMF.RES", "PCPS", key,
                   paste0("commodity ", paste(indicator, collapse = ", "),
                          " (", measure, ")"),
                   start, end)
}

#' Government finance statistics
#'
#' General government revenue or expenditure, from the IMF `GFS_SOO` data flow
#' (Government Finance Statistics, Statement of Operations).
#'
#' @param country Character vector of ISO 3-letter country codes. Required.
#' @param indicator `"revenue"` or `"expenditure"`.
#' @param measure `"xdc"` (domestic currency) or `"pct_gdp"` (percent of GDP).
#' @param sector Institutional sector; `"S13"` (general government) by default,
#'   or `"S1311"` (central government).
#' @param freq Frequency code (`"A"` or `"Q"`).
#' @param start,end Optional first and last year to keep.
#' @return An object of class `imf_tbl` (a data frame).
#' @examples
#' \donttest{
#' imf_gfs("GBR", indicator = "revenue", measure = "pct_gdp")
#' }
#' @seealso [imf_data()]
#' @export
imf_gfs <- function(country, indicator = c("revenue", "expenditure"),
                    measure = c("xdc", "pct_gdp"), sector = "S13",
                    freq = "A", start = NULL, end = NULL) {
  indicator <- match.arg(indicator)
  measure <- match.arg(measure)
  .imf_require(country, "country")
  spec <- switch(indicator,
                 revenue     = c(grp = "G1",  ind = "G1_T"),
                 expenditure = c(grp = "G2M", ind = "G2M_T"))
  transform <- switch(measure, xdc = "XDC", pct_gdp = "POGDP_PT")
  key <- paste0(paste(country, collapse = "+"), ".", sector, ".",
                spec[["grp"]], ".", spec[["ind"]], ".", transform, ".", freq)
  .imf_fetch_named("IMF.STA", "GFS_SOO", key,
                   paste0("government ", indicator, " for ", paste(country, collapse = ", ")),
                   start, end)
}
