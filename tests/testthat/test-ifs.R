test_that("imf_ifs_map returns the crosswalk", {
  m <- imf_ifs_map()
  expect_true(all(c("ifs_code", "description", "agency", "dataflow",
                    "key_template", "default_freq") %in% names(m)))
  expect_true("PCPI_IX" %in% m$ifs_code)
  expect_true(all(m$agency == "IMF.STA"))
})

test_that("imf_ifs_map filters to requested codes", {
  m <- imf_ifs_map("PCPI_IX")
  expect_equal(nrow(m), 1L)
  expect_equal(m$dataflow, "CPI")
})

test_that("imf_ifs_map errors on an unknown code", {
  expect_error(imf_ifs_map("NOPE"), "No IFS mapping")
})

test_that("key builder substitutes country and freq", {
  expect_equal(.imf_ifs_build_key("{country}.CPI._T.IX.{freq}", "GBR", "M"),
               "GBR.CPI._T.IX.M")
  expect_equal(.imf_ifs_build_key("{country}.XDC_USD.PA_RT.{freq}", c("GBR", "USA"), "A"),
               "GBR+USA.XDC_USD.PA_RT.A")
})

test_that("imf_ifs rejects an unknown indicator and missing country", {
  expect_error(imf_ifs("NOPE", country = "GBR"), "Unknown IFS indicator")
  expect_error(imf_ifs("PCPI_IX"), "required")
})

test_that("imf_ifs fetches the UK consumer price index", {
  skip_on_cran()
  skip_if_offline()
  x <- imf_ifs("PCPI_IX", country = "GBR", start = 2015, end = 2020)
  expect_s3_class(x, "imf_tbl")
  expect_equal(unique(x$country), "GBR")
  expect_gt(nrow(x), 0)
  expect_equal(attr(x, "imf_ifs_code"), "PCPI_IX")
})

test_that("imf_ifs fetches a US policy rate", {
  skip_on_cran()
  skip_if_offline()
  x <- imf_ifs("FPOLM_PA", country = "USA", start = 2018, end = 2024)
  expect_s3_class(x, "imf_tbl")
  expect_gt(nrow(x), 0)
})
