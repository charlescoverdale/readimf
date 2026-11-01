# readimf 0.1.1

## Leaving a dimension out now returns every value, as documented

`imf_weo()` documents `country = NULL` and `indicator = NULL` as "every
economy" and "every indicator", and `imf_data()` documents an empty key
element as a wildcard. All of them returned a single blank row instead:
the IMF's SDMX 3.0 API reads an empty key position as "no value", not
"any value". For example `imf_weo(indicator = "NGDP_RPCH")` returned one
empty row; it now returns all 208 economies. Empty key positions are now
sent as the SDMX 3.0 wildcard `*`.

## Examples

Network examples are wrapped in `try()`, so an unreachable IMF API prints
a message instead of failing `R CMD check --run-donttest`.

# readimf 0.1.0

* Initial CRAN release.
* Access International Monetary Fund data through the new IMF 'SDMX' 3.0 API
  at <https://data.imf.org>, returned as a tidy `imf_tbl` with provenance.
* `imf_weo()` downloads World Economic Outlook series, including historical
  forecast vintages.
* `imf_data()` fetches any data flow by key. `imf_dataflows()`, `imf_search()`,
  `imf_codelist()`, `imf_countries()` and `imf_dimensions()` browse the
  catalogue and metadata.
* `imf_ifs()` routes retired International Financial Statistics codes to their
  new thematic data flows, and `imf_ifs_map()` shows the crosswalk.
* Named database wrappers with sensible defaults: `imf_cpi()`, `imf_dots()`
  (bilateral goods trade), `imf_cofer()` (reserve currency composition),
  `imf_commodity()` (primary commodity prices) and `imf_gfs()` (government
  finance). Balance of payments and financial soundness indicators are defined
  in the API but not yet populated, and will follow.
