test_that("dataflow parser extracts id, name, agency, version", {
  j <- list(data = list(dataflows = list(
    list(id = "WEO", name = "World Economic Outlook", agencyID = "IMF.RES", version = "9.0.0"),
    list(id = "CPI", name = "Consumer Price Index",   agencyID = "IMF.STA", version = "5.0.0")
  )))
  df <- .imf_parse_dataflows(j)
  expect_named(df, c("id", "name", "agency", "version"))
  expect_equal(df$id, c("WEO", "CPI"))
  expect_equal(df$agency, c("IMF.RES", "IMF.STA"))
})

test_that("codelist parser extracts code and label", {
  j <- list(data = list(codelists = list(list(codes = list(
    list(id = "GBR", name = "United Kingdom"),
    list(id = "USA", name = "United States")
  )))))
  df <- .imf_parse_codelist(j)
  expect_named(df, c("code", "label"))
  expect_equal(df$code, c("GBR", "USA"))
  expect_equal(df$label[1], "United Kingdom")
})

test_that("imf_search filters the catalogue without hitting the network", {
  .imf_env$dataflows <- data.frame(
    id = c("WEO", "CPI", "BOP"),
    name = c("World Economic Outlook", "Consumer Price Index", "Balance of Payments"),
    agency = c("IMF.RES", "IMF.STA", "IMF.STA"),
    version = "1.0.0", stringsAsFactors = FALSE)
  on.exit(rm(list = "dataflows", envir = .imf_env), add = TRUE)

  hits <- imf_search("price")
  expect_true("CPI" %in% hits$id)
  expect_false("WEO" %in% hits$id)
})

test_that("imf_dataflows hits the live catalogue", {
  skip_on_cran()
  skip_if_offline()
  df <- imf_dataflows(refresh = TRUE)
  expect_gt(nrow(df), 150)
  expect_true(all(c("id", "name", "agency", "version") %in% names(df)))
  expect_true("WEO" %in% df$id)
})

test_that("imf_countries returns ISO-3 country codes", {
  skip_on_cran()
  skip_if_offline()
  cc <- imf_countries()
  expect_true(all(c("code", "label") %in% names(cc)))
  expect_true("GBR" %in% cc$code)
  expect_gt(nrow(cc), 200)
})

test_that("imf_dimensions returns the WEO key order", {
  skip_on_cran()
  skip_if_offline()
  d <- imf_dimensions("WEO")
  expect_equal(d$dimension, c("COUNTRY", "INDICATOR", "FREQUENCY"))
})

test_that("imf_data fetches a generic series and filters by year", {
  skip_on_cran()
  skip_if_offline()
  x <- imf_data("WEO", key = "GBR.NGDP_RPCH.A", start = 2018, end = 2020)
  expect_s3_class(x, "imf_tbl")
  expect_true(all(x$period >= 2018 & x$period <= 2020))
  expect_equal(unique(x$country), "GBR")
})
