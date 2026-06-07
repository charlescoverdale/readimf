## Curated crosswalk: legacy IMF IFS indicator codes -> SDMX 3.0 data flows.
##
## Every mapping was verified against the live API (a fully specified key that
## returns data) on 2026-06-07. The {country} and {freq} placeholders are
## substituted at call time by imf_ifs(). Country coverage in the new data
## flows varies, especially for the MFS_IR interest rates. Broad money
## (FMB_XDC) and the monetary base (FASMB_XDC) are deferred to a later version
## pending a clean unit-dimension mapping.
##
## Run from the package root:  source("data-raw/ifs_crosswalk.R")

ifs_crosswalk <- data.frame(
  ifs_code = c(
    "PCPI_IX", "PCPIPCH", "ENDA_XDC_USD_RATE", "ENDE_XDC_USD_RATE",
    "FPOLM_PA", "FIMM_PA", "FIDR_PA", "FILR_PA", "RAFA_USD", "AIP_IX", "LUR_PT"),
  description = c(
    "Consumer price index, all items",
    "Consumer price inflation, year-on-year percent change",
    "Exchange rate, domestic currency per USD, period average",
    "Exchange rate, domestic currency per USD, end of period",
    "Central bank policy rate, percent per annum",
    "Money market rate, percent per annum",
    "Deposit rate, percent per annum",
    "Lending rate, percent per annum",
    "Total reserves excluding gold, US dollars",
    "Industrial production index",
    "Unemployment rate, percent"),
  agency = "IMF.STA",
  dataflow = c(
    "CPI", "CPI", "ER", "ER", "MFS_IR", "MFS_IR", "MFS_IR", "MFS_IR",
    "IL", "PI", "LS"),
  key_template = c(
    "{country}.CPI._T.IX.{freq}",
    "{country}.CPI._T.YOY_PCH_PA_PT.{freq}",
    "{country}.XDC_USD.PA_RT.{freq}",
    "{country}.XDC_USD.EOP_RT.{freq}",
    "{country}.MFS166_RT_PT_A_PT.{freq}",
    "{country}.MMRT_RT_PT_A_PT.{freq}",
    "{country}.MFS135_RT_PT_A_PT.{freq}",
    "{country}.MFS162_RT_PT_A_PT.{freq}",
    "{country}.RXF11_REVS.USD.{freq}",
    "{country}.IND.IX.{freq}",
    "{country}.U.PT.{freq}"),
  default_freq = "M",
  notes = c(
    "All-items index.",
    "Year-on-year percent change.",
    "Period average.",
    "End of period.",
    "Coverage varies by country.",
    "Coverage varies by country.",
    "Coverage varies by country.",
    "Coverage varies by country.",
    "US dollars; the SCALE column applies.",
    "Index.",
    "Monthly or quarterly (use freq = Q where monthly is unavailable)."),
  stringsAsFactors = FALSE)

save(ifs_crosswalk, file = "R/sysdata.rda", version = 2)
