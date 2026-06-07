# readimf
[![CRAN status](https://www.r-pkg.org/badges/version/readimf)](https://CRAN.R-project.org/package=readimf) [![CRAN downloads](https://cranlogs.r-pkg.org/badges/readimf)](https://CRAN.R-project.org/package=readimf) [![Total Downloads](https://cranlogs.r-pkg.org/badges/grand-total/readimf)](https://CRAN.R-project.org/package=readimf) [![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

**readimf** provides clean, tidy access to International Monetary Fund data through the new IMF SDMX 3.0 REST API at [data.imf.org](https://data.imf.org), directly from R.

## What is the IMF?

The International Monetary Fund is one of the two Bretton Woods institutions, founded in 1944 and based in Washington DC, with 190 member countries. Alongside its surveillance and lending work, it is one of the most important sources of internationally comparable macroeconomic and financial statistics. Its flagship datasets include the World Economic Outlook (WEO) forecasts, the Direction of Trade Statistics (bilateral goods trade), the Currency Composition of Official Foreign Exchange Reserves (COFER), Government Finance Statistics, Primary Commodity Prices, and consumer prices.

For decades much of this lived under International Financial Statistics (IFS), a single sprawling database of national accounts, prices, money, and external sector series. The IMF has now retired IFS and split its contents across many smaller thematic data flows.

## The IMF data portal and SDMX 3.0 API

The IMF has moved its data dissemination to a new portal at [data.imf.org](https://data.imf.org), built on the SDMX 3.0 REST standard. SDMX (Statistical Data and Metadata eXchange) is the ISO standard for statistical data used by the ECB, BIS, Eurostat, and the OECD, so the IMF now speaks the same protocol as its peers.

Querying it directly means constructing dot-delimited dimension keys (opaque strings like `GBR.NGDP_RPCH.A` that encode country, indicator, and frequency) and parsing the response. `readimf` abstracts that away: it builds the keys for the common databases, reads the compact SDMX-CSV representation of each query, and returns a tidy data frame. It depends only on `cli`, `httr2`, `jsonlite`, and base R.

## How is readimf different from imfr?

The existing [imfr](https://cran.r-project.org/package=imfr) package wraps the IMF's legacy JSON web service, the data source that powered most IMF-in-R workflows for years. That service is being retired as the Fund moves to the new portal, and when IFS was restructured the old series codes stopped resolving with no official crosswalk to their replacements. `readimf` is built for the new world instead:

- **Targets the supported API.** It speaks to the current SDMX 3.0 REST endpoint at data.imf.org, not the deprecated legacy service.
- **Bridges the IFS migration.** `imf_ifs()` accepts a retired IFS code and routes it to its new data flow and key, and `imf_ifs_map()` shows the full crosswalk. This is the gap nothing else fills.
- **Named wrappers with sensible defaults.** `imf_cpi()`, `imf_dots()`, `imf_cofer()`, `imf_commodity()`, and `imf_gfs()` cover the popular databases without you ever building a key by hand.
- **Historical WEO vintages.** `imf_weo(vintage = "2025-10")` fetches a past forecast release for forecast evaluation.
- **Lightweight and resilient.** A small dependency stack (`cli`, `httr2`, `jsonlite`), and a bundled catalogue snapshot that is returned automatically if the API is unreachable.
- **Provenance built in.** Every result is an `imf_tbl` that prints with a one-line summary (agency, data flow, vintage, coverage) and carries the source URL and retrieval timestamp as attributes.

## Installation

```r
install.packages("readimf")

# Or install the development version from GitHub
# install.packages("devtools")
devtools::install_github("charlescoverdale/readimf")
```

## API keys

The World Economic Outlook and several other databases are open and need no key. Some restricted data flows return nothing for wildcard queries unless you authenticate. To use a key, request one from the IMF data portal and store it in your `.Renviron` as `IMF_API_KEY`; `readimf` picks it up automatically.

```r
# In ~/.Renviron (then restart R)
IMF_API_KEY=your_key_here
```

## Finding data

The IMF publishes hundreds of data flows. Three functions help you locate the one you need and work out how to query it.

```r
library(readimf)

imf_search("consumer price")     # search the catalogue by id or name
imf_dataflows()                  # list every data flow (id, name, agency, version)
imf_dimensions("WEO")            # the ordered dimensions needed to build a key
imf_codelist("CL_COUNTRY")       # valid codes for a dimension
```

## Examples

### World Economic Outlook

The WEO is open, so this needs no API key.

```r
library(readimf)

# Real GDP growth for the UK and US
imf_weo("NGDP_RPCH", country = c("GBR", "USA"), start = 2021, end = 2024)
#> IMF data: IMF.RES/WEO
#> 8 rows, 2 economies, 2021 to 2024
#>   country indicator freq period    value
#> 1     GBR NGDP_RPCH    A   2021 8.543112
#> 2     GBR NGDP_RPCH    A   2022 5.149704
#> 3     GBR NGDP_RPCH    A   2023 0.271650
#> 4     GBR NGDP_RPCH    A   2024 1.088126
#> 5     USA NGDP_RPCH    A   2021 6.151865
#> 6     USA NGDP_RPCH    A   2022 2.524222
#> 7     USA NGDP_RPCH    A   2023 2.934535
#> 8     USA NGDP_RPCH    A   2024 2.793116

# A historical forecast vintage, for forecast evaluation
imf_weo("NGDP_RPCH", country = "GBR", vintage = "2025-10")
```

### The IFS migration: where did my series go?

When the IMF retired International Financial Statistics, series like the consumer price index `PCPI_IX` scattered across new data flows with no published crosswalk. `imf_ifs()` takes the old code and fetches from the new home; `imf_ifs_map()` shows the mapping without downloading anything.

```r
# See where each retired IFS series now lives
imf_ifs_map()
#>            ifs_code                                           description dataflow
#> 1           PCPI_IX                       Consumer price index, all items      CPI
#> 2           PCPIPCH Consumer price inflation, year-on-year percent change      CPI
#> 3 ENDA_XDC_USD_RATE Exchange rate, domestic currency per USD, period average      ER
#> 4          FPOLM_PA          Central bank policy rate, percent per annum   MFS_IR
#> ... (the full table also has agency, key_template and default_freq columns)

# Fetch by the old IFS code; readimf routes it to the new CPI data flow
imf_ifs("PCPI_IX", country = "GBR", start = 2015)
```

### Named database wrappers

Common databases have named wrappers that set sensible defaults, so you never build a key by hand.

```r
# US dollar share of allocated world reserves (COFER, quarterly)
imf_cofer(currency = "USD", measure = "share", start = 2022)
#> IMF data: IMF.STA/COFER
#> 16 rows, 1 economy, 2022-Q1 to 2025-Q4
#>   country indicator fxr_currency type_of_transformation freq  period    value
#> 1    G001     AFXRA       CI_USD                SHRO_PT    Q 2022-Q1 59.41740
#> 2    G001     AFXRA       CI_USD                SHRO_PT    Q 2022-Q2 59.99506
#> 3    G001     AFXRA       CI_USD                SHRO_PT    Q 2022-Q3 60.43338
#> 4    G001     AFXRA       CI_USD                SHRO_PT    Q 2022-Q4 58.95171
#> ...

# WTI crude oil price, US dollars per barrel (a global series, no country needed)
imf_commodity("POILWTI", measure = "usd", start = 2024)
#> IMF data: IMF.RES/PCPS
#> 29 rows, 1 economy, 2024-M01 to 2026-M05
#>    country indicator data_transformation freq   period    value
#> 1     G001   POILWTI                 USD    M 2024-M01 74.00304
#> 2     G001   POILWTI                 USD    M 2024-M02 77.36381
#> 3     G001   POILWTI                 USD    M 2024-M03 81.40571
#> ...

imf_cpi("GBR", measure = "inflation")        # consumer price inflation
imf_dots("USA", "GBR", flow = "exports")     # bilateral goods trade
imf_gfs("GBR", indicator = "revenue")        # general government revenue
```

### Fetch any data flow by key

The wrappers cover the popular databases, but you can reach anything on the portal with `imf_data()`. Use `imf_dimensions()` to learn the key order and `imf_codelist()` to find valid codes.

```r
imf_data("WEO", "GBR.NGDP_RPCH.A", start = 2015, end = 2024)
```

## Vignette

* `vignette("readimf")` - getting started: discovering data flows, building keys, the IFS crosswalk, and WEO vintages.

## Functions

**World Economic Outlook**

| Function | Description |
|---|---|
| `imf_weo()` | WEO forecasts and history, including historical release vintages |

**Named databases**

| Function | Description |
|---|---|
| `imf_cpi()` | Consumer prices: all-items index or year-on-year inflation |
| `imf_dots()` | Bilateral goods trade (successor to Direction of Trade Statistics) |
| `imf_cofer()` | Currency composition of official foreign exchange reserves |
| `imf_commodity()` | Primary commodity prices (Primary Commodity Price System) |
| `imf_gfs()` | Government finance: general government revenue or expenditure |

**IFS migration**

| Function | Description |
|---|---|
| `imf_ifs()` | Fetch a retired IFS series from its new data flow |
| `imf_ifs_map()` | Show the IFS to SDMX 3.0 crosswalk |

**Generic access**

| Function | Description |
|---|---|
| `imf_data()` | Fetch any data flow by key or per-dimension value list |

**Discovery and metadata**

| Function | Description |
|---|---|
| `imf_dataflows()` | List the full data flow catalogue (memoised, with offline fallback) |
| `imf_search()` | Search the catalogue by id or name |
| `imf_dimensions()` | Inspect a data flow's ordered dimensions |
| `imf_codelist()` | Fetch a codelist (the valid codes and labels for a dimension) |
| `imf_countries()` | Master country and area codelist |

## Related packages

| Package | Description |
|---|---|
| [`readoecd`](https://github.com/charlescoverdale/readoecd) | OECD international data |
| [`readecb`](https://github.com/charlescoverdale/readecb) | European Central Bank data |
| [`fred`](https://github.com/charlescoverdale/fred) | US Federal Reserve (FRED) data |
| [`boe`](https://github.com/charlescoverdale/boe) | Bank of England data |
| [`comtrade`](https://github.com/charlescoverdale/comtrade) | UN Comtrade international trade data |
| [`debtkit`](https://github.com/charlescoverdale/debtkit) | Debt sustainability analysis |
| [`nowcast`](https://github.com/charlescoverdale/nowcast) | Economic nowcasting (bridge, MIDAS, DFM) |

## Issues

Please report bugs or requests at <https://github.com/charlescoverdale/readimf/issues>.

## Attribution

`readimf` is an independent, open-source project. It is not affiliated with, endorsed by, or certified by the International Monetary Fund.

## Keywords

International Monetary Fund, IMF, World Economic Outlook, WEO, SDMX, International Financial Statistics, IFS, COFER, Direction of Trade, government finance, commodity prices, consumer prices, macroeconomic data, international data, R package
