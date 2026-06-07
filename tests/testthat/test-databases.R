test_that("named wrappers validate their arguments", {
  expect_error(imf_cpi(NULL), "required")
  expect_error(imf_cpi("GBR", measure = "nope"), "should be one of")
  expect_error(imf_gfs("GBR", indicator = "nope"), "should be one of")
  expect_error(imf_dots("USA", NULL), "required")
})

test_that("imf_cpi fetches UK inflation", {
  skip_on_cran()
  skip_if_offline()
  x <- imf_cpi("GBR", measure = "inflation", start = 2016, end = 2020)
  expect_s3_class(x, "imf_tbl")
  expect_equal(unique(x$country), "GBR")
  expect_gt(nrow(x), 0)
})

test_that("imf_dots fetches US-UK goods exports", {
  skip_on_cran()
  skip_if_offline()
  x <- imf_dots("USA", "GBR", flow = "exports", start = 2020, end = 2022)
  expect_s3_class(x, "imf_tbl")
  expect_gt(nrow(x), 0)
})

test_that("imf_cofer fetches the USD reserve share", {
  skip_on_cran()
  skip_if_offline()
  x <- imf_cofer(currency = "USD", measure = "share", start = 2015)
  expect_s3_class(x, "imf_tbl")
  expect_gt(nrow(x), 0)
  expect_true(all(x$value > 40 & x$value < 80, na.rm = TRUE))
})

test_that("imf_commodity fetches the WTI crude price", {
  skip_on_cran()
  skip_if_offline()
  x <- imf_commodity("POILWTI", measure = "usd", start = 2018, end = 2022)
  expect_s3_class(x, "imf_tbl")
  expect_gt(nrow(x), 0)
})

test_that("imf_gfs fetches UK government revenue", {
  skip_on_cran()
  skip_if_offline()
  x <- imf_gfs("GBR", indicator = "revenue", measure = "pct_gdp", start = 2015, end = 2022)
  expect_s3_class(x, "imf_tbl")
  expect_equal(unique(x$country), "GBR")
  expect_gt(nrow(x), 0)
})
