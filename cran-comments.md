# CRAN submission comments: readimf 0.1.1

## Reason for this submission

Bug fix. Calls that leave a key dimension unspecified, documented as
returning every value, returned an empty result because the IMF's SDMX
3.0 API needs an explicit wildcard. Details in NEWS.md.

## R CMD check results

0 errors | 0 warnings | 0 notes (CRAN settings, R 4.5.2, macOS).

Network examples are now wrapped in `try()` inside `\donttest{}`, so an
unreachable API prints a message rather than failing the check.

Tests that reach the IMF API are skipped on CRAN.

## Downstream dependencies

None on CRAN.
