# Session-level memoisation for the (large, stable) data flow catalogue.
.imf_env <- new.env(parent = emptyenv())

# Coerce a possibly-NULL JSON scalar to a length-1 character.
.imf_chr <- function(v) if (is.null(v)) NA_character_ else as.character(v)[[1]]

# Internal: GET a structure / metadata resource and parse the JSON body.
.imf_get_json <- function(path) {
  url <- paste0(.imf_base_url(), path)
  req <- httr2::request(url)
  req <- httr2::req_headers(req, Accept = "application/json")
  req <- httr2::req_user_agent(req, .imf_user_agent())
  req <- httr2::req_retry(req, max_tries = 4L)
  req <- httr2::req_timeout(req, 60L)
  resp <- httr2::req_perform(req)
  jsonlite::fromJSON(httr2::resp_body_string(resp), simplifyVector = FALSE)
}

# --- Data flow catalogue ----------------------------------------------------

.imf_parse_dataflows <- function(j) {
  fl <- j$data$dataflows
  data.frame(
    id      = vapply(fl, function(x) .imf_chr(x$id), character(1)),
    name    = vapply(fl, function(x) .imf_chr(x$name), character(1)),
    agency  = vapply(fl, function(x) .imf_chr(x$agencyID), character(1)),
    version = vapply(fl, function(x) .imf_chr(x$version), character(1)),
    stringsAsFactors = FALSE
  )
}

.imf_fetch_dataflows <- function() .imf_parse_dataflows(.imf_get_json("structure/dataflow"))

#' List the IMF data flow catalogue
#'
#' Return every dataset (data flow) published on the IMF 'SDMX' 3.0 portal:
#' its id, descriptive name, owning agency and version. The catalogue is
#' fetched once per session and memoised; pass `refresh = TRUE` to refetch. If
#' the API cannot be reached, a snapshot bundled with the package is returned.
#'
#' @param refresh Logical. Refetch from the API instead of using the
#'   session-memoised catalogue.
#' @return A data frame with columns `id`, `name`, `agency` and `version`.
#' @examples
#' \donttest{
#' flows <- imf_dataflows()
#' head(flows)
#' }
#' @export
imf_dataflows <- function(refresh = FALSE) {
  if (!refresh && !is.null(.imf_env$dataflows)) return(.imf_env$dataflows)
  out <- tryCatch(.imf_fetch_dataflows(), error = function(e) NULL)
  if (is.null(out)) {
    snap <- system.file("extdata", "dataflows.rds", package = "readimf")
    if (nzchar(snap)) {
      cli::cli_warn("Could not reach the IMF API; returning the bundled catalogue snapshot.")
      out <- readRDS(snap)
    } else {
      cli::cli_abort("Could not reach the IMF API and no catalogue snapshot is bundled.")
    }
  }
  .imf_env$dataflows <- out
  out
}

#' Search the IMF data flow catalogue
#'
#' Case-insensitive search over data flow ids and names.
#'
#' @param pattern Regular expression or plain text to match.
#' @return A data frame: the matching rows of [imf_dataflows()].
#' @examples
#' \donttest{
#' imf_search("consumer price")
#' imf_search("balance of payments")
#' }
#' @export
imf_search <- function(pattern) {
  catalogue <- imf_dataflows()
  hits <- grepl(pattern, paste(catalogue$id, catalogue$name), ignore.case = TRUE)
  out <- catalogue[hits, , drop = FALSE]
  rownames(out) <- NULL
  out
}

# --- Codelists --------------------------------------------------------------

.imf_parse_codelist <- function(j) {
  codes <- j$data$codelists[[1]]$codes
  data.frame(
    code  = vapply(codes, function(x) .imf_chr(x$id), character(1)),
    label = vapply(codes, function(x) .imf_chr(x$name), character(1)),
    stringsAsFactors = FALSE
  )
}

#' Fetch an IMF codelist
#'
#' Download a codelist (the valid codes and labels for a dimension), for
#' example the country list or an indicator list, as a tidy data frame.
#'
#' @param id Codelist id, for example `"CL_COUNTRY"` or `"CL_WEO_INDICATOR"`.
#' @param agency Owning agency. Most shared codelists are `"IMF"`; some belong
#'   to a department, for example `"IMF.RES"` for WEO codelists.
#' @param version Codelist version; `"+"` (the default) requests the latest.
#' @return A data frame with columns `code` and `label`.
#' @examples
#' \donttest{
#' imf_codelist("CL_WEO_INDICATOR", agency = "IMF.RES")
#' }
#' @export
imf_codelist <- function(id, agency = "IMF", version = "+") {
  path <- sprintf("structure/codelist/%s/%s/%s", agency, id, version)
  .imf_parse_codelist(.imf_get_json(path))
}

#' IMF country codelist
#'
#' Convenience wrapper returning the master country and area codelist
#' (ISO 3-letter codes and names).
#'
#' @return A data frame with columns `code` and `label`.
#' @examples
#' \donttest{
#' imf_countries()
#' }
#' @export
imf_countries <- function() imf_codelist("CL_COUNTRY", agency = "IMF")

# --- Data structure (dimensions) -------------------------------------------

.imf_agency_for <- function(dataflow) {
  catalogue <- imf_dataflows()
  hit <- catalogue$agency[catalogue$id == dataflow]
  if (length(hit) == 0L) {
    cli::cli_abort(c(
      "Unknown data flow {.val {dataflow}}.",
      "i" = "See {.fn imf_dataflows} or {.fn imf_search}."
    ))
  }
  hit[[1]]
}

#' Inspect the dimensions of a data flow
#'
#' Return the ordered dimensions of a data flow's data structure. This is the
#' order in which values must be supplied when building a key for [imf_data()].
#'
#' @param dataflow Data flow id, for example `"WEO"` or `"CPI"`.
#' @param agency Owning agency. If `NULL` it is looked up from the catalogue.
#' @return A data frame with columns `position` (zero-based) and `dimension`.
#' @examples
#' \donttest{
#' imf_dimensions("WEO")
#' }
#' @export
imf_dimensions <- function(dataflow, agency = NULL) {
  if (is.null(agency)) agency <- .imf_agency_for(dataflow)
  j <- .imf_get_json(sprintf("structure/dataflow/%s/%s/+?references=datastructure",
                             agency, dataflow))
  ds <- tryCatch(j$data$dataStructures[[1]], error = function(e) NULL)
  if (is.null(ds)) {
    urn <- .imf_chr(j$data$dataflows[[1]]$structure)
    m <- regmatches(urn, regexec("DataStructure=([^:]+):([^(]+)\\(([^)]+)\\)", urn))[[1]]
    if (length(m) < 4L) {
      cli::cli_abort("Could not resolve the data structure for {.val {dataflow}}.")
    }
    j <- .imf_get_json(sprintf("structure/datastructure/%s/%s/+", m[[2]], m[[3]]))
    ds <- j$data$dataStructures[[1]]
  }
  dims <- ds$dataStructureComponents$dimensionList$dimensions
  data.frame(
    position  = seq_along(dims) - 1L,
    dimension = vapply(dims, function(x) .imf_chr(x$id), character(1)),
    stringsAsFactors = FALSE
  )
}

# --- Generic data access ----------------------------------------------------

.imf_year <- function(period) suppressWarnings(as.integer(substr(as.character(period), 1L, 4L)))

#' Fetch data from any IMF data flow
#'
#' The general-purpose accessor behind the database-specific wrappers. Supply a
#' data flow id and a key. Use [imf_dimensions()] to discover the dimension
#' order and [imf_codelist()] to discover valid codes.
#'
#' @param dataflow Data flow id, for example `"WEO"` or `"CPI"`.
#' @param key Either a ready-made key string (for example `"GBR.NGDP_RPCH.A"`),
#'   or a list of values per dimension in order (for example
#'   `list(c("GBR", "USA"), "NGDP_RPCH", "A")`), or `NULL` for all series. An
#'   empty element is a wildcard for that dimension.
#' @param agency Owning agency. If `NULL` it is looked up from the catalogue.
#' @param version Data flow version; `"+"` (the default) requests the latest.
#' @param start,end Optional first and last year to keep.
#' @return An object of class `imf_tbl` (a data frame).
#' @examples
#' \donttest{
#' imf_data("WEO", "GBR.NGDP_RPCH.A", start = 2015, end = 2024)
#' }
#' @export
imf_data <- function(dataflow, key = NULL, agency = NULL, version = "+",
                     start = NULL, end = NULL) {
  if (is.null(agency)) agency <- .imf_agency_for(dataflow)
  k <- if (is.null(key)) {
    ""
  } else if (is.character(key) && length(key) == 1L) {
    key
  } else {
    do.call(.imf_key, as.list(key))
  }
  raw <- .imf_fetch(agency = agency, flow = dataflow, key = k,
                    version = version, api_key = .imf_api_key())
  out <- .imf_tidy(raw)
  if ((!is.null(start) || !is.null(end)) && "period" %in% names(out)) {
    yr <- .imf_year(out$period)
    keep <- rep(TRUE, length(yr))
    if (!is.null(start)) keep <- keep & (is.na(yr) | yr >= start)
    if (!is.null(end))   keep <- keep & (is.na(yr) | yr <= end)
    out <- out[keep, , drop = FALSE]
    rownames(out) <- NULL
  }
  .new_imf_tbl(out, dataflow = dataflow, agency = agency,
               source = attr(raw, "imf_url"), vintage = NULL)
}
