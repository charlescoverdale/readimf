test_that("key builder joins dimensions and values", {
  expect_equal(.imf_key("GBR", "NGDP_RPCH", "A"), "GBR.NGDP_RPCH.A")
  expect_equal(.imf_key(c("GBR", "USA"), "NGDP_RPCH", "A"), "GBR+USA.NGDP_RPCH.A")
  expect_equal(.imf_key(NULL, "NGDP_RPCH", "A"), ".NGDP_RPCH.A")
  expect_equal(.imf_key(NULL, NULL, "A"), "..A")
})

test_that("WEO vintage resolver maps tags to data flows", {
  expect_equal(.imf_weo_flow("latest"), "WEO")
  expect_equal(.imf_weo_flow(NULL), "WEO")
  expect_equal(.imf_weo_flow("2025-10"), "WEO_2025_OCT_VINTAGE")
  expect_equal(.imf_weo_flow("2024-04"), "WEO_2024_APR_VINTAGE")
  expect_error(.imf_weo_flow("2025"), "latest")
})

test_that("tidy reduces SDMX-CSV to dimensions, period and value", {
  raw <- utils::read.csv(
    text = paste(
      "STRUCTURE[;],STRUCTURE_ID,ACTION,COUNTRY,INDICATOR,FREQUENCY,TIME_PERIOD,OBS_VALUE,SCALE,UNIT",
      "dataflow,IMF.RES:WEO(9.0.0),R,GBR,NGDP_RPCH,A,2021,7.6,0,PT",
      "dataflow,IMF.RES:WEO(9.0.0),R,GBR,NGDP_RPCH,A,2020,-10.4,0,PT",
      sep = "\n"),
    check.names = FALSE, stringsAsFactors = FALSE)

  out <- .imf_tidy(raw)

  expect_named(out, c("country", "indicator", "freq", "period", "value"))
  expect_type(out$value, "double")
  expect_type(out$period, "integer")
  expect_false(any(grepl("^structure|^action|scale|unit", names(out))))
  # rows sorted by period ascending
  expect_equal(out$period, c(2020L, 2021L))
})
