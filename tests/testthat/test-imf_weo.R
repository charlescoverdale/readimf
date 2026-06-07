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
