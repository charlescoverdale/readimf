# Internal helpers for talking to the IMF 'SDMX' 3.0 REST API.

# Base URL for the IMF data API. Overridable via option for testing or mocking.
.imf_base_url <- function() {
  getOption("readimf.base_url", "https://api.imf.org/external/sdmx/3.0/")
}

.imf_user_agent <- function() {
  "readimf R package (https://github.com/charlescoverdale/readimf)"
}

# Read the optional IMF API subscription key from the environment.
.imf_api_key <- function() {
  key <- Sys.getenv("IMF_API_KEY", unset = "")
  if (nzchar(key)) key else NULL
}

# Build an 'SDMX' key from positional dimension values. Each argument is a
# character vector (or NULL for a wildcard). Values within one dimension are
# joined with "+"; successive dimensions are joined with ".".
.imf_key <- function(...) {
  dims <- list(...)
  parts <- vapply(dims, function(p) {
    if (is.null(p) || length(p) == 0L) "" else paste(as.character(p), collapse = "+")
  }, character(1))
  paste(parts, collapse = ".")
}

# Perform a data query against one data flow and return the raw data frame
# parsed from the 'SDMX-CSV' representation.
.imf_fetch <- function(agency, flow, key = "", version = "+", api_key = NULL) {
  url <- paste0(.imf_base_url(), "data/dataflow/",
                agency, "/", flow, "/", version, "/", key)

  req <- httr2::request(url)
  req <- httr2::req_headers(req, Accept = "application/vnd.sdmx.data+csv;version=2.0.0")
  req <- httr2::req_user_agent(req, .imf_user_agent())
  if (!is.null(api_key) && nzchar(api_key)) {
    req <- httr2::req_headers(req, "Ocp-Apim-Subscription-Key" = api_key)
  }
  req <- httr2::req_retry(req, max_tries = 4L)
  req <- httr2::req_timeout(req, 60L)

  resp <- httr2::req_perform(req)
  txt <- httr2::resp_body_string(resp)

  df <- tryCatch(
    utils::read.csv(text = txt, stringsAsFactors = FALSE, check.names = FALSE),
    error = function(e) data.frame()
  )

  if (nrow(df) == 0L) {
    cli::cli_abort(c(
      "The IMF API returned no observations for data flow {.val {flow}}.",
      "i" = "Restricted data flows return nothing for wildcard queries without a key.",
      "i" = "Set {.envvar IMF_API_KEY}, or name every dimension explicitly.",
      "i" = "The World Economic Outlook ({.fn imf_weo}) is open and needs no key."
    ))
  }

  attr(df, "imf_url") <- url
  df
}

# Tidy a raw 'SDMX-CSV' data frame down to dimensions, period and value.
.imf_tidy <- function(df) {
  nms <- names(df)
  tp <- match("TIME_PERIOD", nms)
  ov <- match("OBS_VALUE", nms)
  if (is.na(tp) || is.na(ov)) {
    names(df) <- tolower(nms)
    return(df)
  }

  lead <- nms[seq_len(tp - 1L)]
  dims <- lead[!grepl("^STRUCTURE", lead) & lead != "ACTION"]
  out <- df[, c(dims, "TIME_PERIOD", "OBS_VALUE"), drop = FALSE]

  names(out) <- tolower(names(out))
  names(out)[names(out) == "time_period"] <- "period"
  names(out)[names(out) == "obs_value"]   <- "value"
  names(out)[names(out) == "frequency"]   <- "freq"

  out$value <- suppressWarnings(as.numeric(out$value))
  p <- as.character(out$period)
  if (length(p) && all(grepl("^[0-9]{4}$", p))) out$period <- as.integer(out$period)

  ord <- intersect(c("country", "indicator", "period"), names(out))
  if (length(ord)) out <- out[do.call(order, unname(out[ord])), , drop = FALSE]
  rownames(out) <- NULL
  out
}
