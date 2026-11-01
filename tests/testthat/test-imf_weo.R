test_that("imf_weo fetches WEO data from the live API", {
  skip_on_cran()
  skip_if_offline()

  x <- imf_weo("NGDP_RPCH", country = c("GBR", "USA"), start = 2018, end = 2022)

  expect_s3_class(x, "imf_tbl")
  expect_true(all(c("country", "indicator", "freq", "period", "value") %in% names(x)))
  expect_setequal(unique(x$country), c("GBR", "USA"))
  expect_true(all(x$period >= 2018 & x$period <= 2022))
  expect_type(x$value, "double")
  expect_false(anyNA(x$value))
})

test_that("imf_weo with country = NULL returns every economy", {
  skip_on_cran()
  skip_if_offline()
  w <- imf_weo(indicator = "NGDP_RPCH", start = 2024, end = 2024)
  # The empty-key form returned a single blank row before 0.1.1.
  expect_gt(length(unique(w$country)), 150L)
  expect_false(anyNA(w$value[w$country == "GBR"]))
})
