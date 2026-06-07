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
