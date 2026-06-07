## Submission

This is a new submission (readimf 0.1.0).

## R CMD check results

Local `R CMD check --as-cran` (macOS aarch64, R 4.5.2): 0 errors | 0 warnings | 0 notes.

On CRAN's incoming checks I expect the standard "New submission" NOTE.

## Notes for the reviewer

* The package wraps the public IMF data portal at <https://data.imf.org>,
  served through the IMF 'SDMX' 3.0 REST API. The World Economic Outlook needs
  no authentication; an optional API key (read from the `IMF_API_KEY`
  environment variable) unlocks wildcard queries on restricted databases. No
  key is embedded in the package.
* <https://data.imf.org> is valid: it resolves in a browser and via R's
  `curlGetHeaders()`. The IMF web application firewall can intermittently
  return HTTP 403 to automated link checkers using certain user agents, so the
  URL may be reported as "possibly invalid"; it is correct.
* All examples that contact the API are wrapped in `\donttest{}`. All tests
  that contact the network use `skip_on_cran()` and `skip_if_offline()`.

## Test environments

* local: macOS (aarch64), R 4.5.2
