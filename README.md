# readimf

<!-- badges: start -->
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![CRAN status](https://www.r-pkg.org/badges/version/readimf)](https://CRAN.R-project.org/package=readimf)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

`readimf` provides tidy access to International Monetary Fund data through the
new IMF SDMX 3.0 REST API at [data.imf.org](https://data.imf.org). It replaces
the retired `imfr` workflow and, uniquely, bridges the gap left when the IMF
retired International Financial Statistics (IFS) and split it across many new
data flows.

It depends only on `cli`, `httr2`, `jsonlite` and `utils`.

## Installation

```r
# install.packages("pak")
pak::pak("charlescoverdale/readimf")
```

## World Economic Outlook

```r
library(readimf)

# Real GDP growth for the UK and US
imf_weo("NGDP_RPCH", country = c("GBR", "USA"), start = 2018, end = 2024)

# A historical forecast vintage, for forecast evaluation
imf_weo("NGDP_RPCH", country = "GBR", vintage = "2025-10")
```

## Migrating from imfr: where did IFS go?

When the IMF moved to SDMX 3.0 it retired International Financial Statistics and
scattered its series across thematic data flows (`CPI`, `ER`, `MFS_IR` and
others) with no official crosswalk. `imf_ifs()` accepts the old IFS codes and
routes them to their new homes:

```r
# UK consumer price index, the series formerly known as IFS PCPI_IX
imf_ifs("PCPI_IX", country = "GBR", start = 2015)

# See the full crosswalk: which new data flow each IFS code now lives in
imf_ifs_map()
```

## Discovery

```r
imf_search("consumer price")                 # find a data flow
imf_dimensions("CPI")                         # see how to build a key
imf_data("CPI", key = "GBR.CPI._T.IX.M", start = 2020)   # fetch anything by key
```

## Named database wrappers

Common databases have named wrappers that set sensible defaults:

```r
imf_cpi("GBR", measure = "inflation")           # consumer price inflation
imf_dots("USA", "GBR", flow = "exports")        # bilateral goods trade
imf_cofer(currency = "USD", measure = "share")  # USD share of world reserves
imf_commodity("POILWTI", measure = "usd")       # WTI crude oil price
imf_gfs("GBR", indicator = "revenue")           # general government revenue
```

## API keys

The World Economic Outlook is open and needs no key. Restricted databases
(consumer prices, balance of payments and the other former IFS tables) accept
an optional API key supplied through the `IMF_API_KEY` environment variable.

`readimf` is an independent project and is not affiliated with the IMF.
