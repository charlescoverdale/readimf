## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.
* The remaining note ("unable to verify current time") is a transient
  environment check unrelated to the package.

## Test environments

* local macOS, R 4.5.2

## Notes

* This is a new submission (version 0.1.0).
* The package wraps the public IMF data API at <https://data.imf.org>. No
  authentication is required for the World Economic Outlook; an optional API
  key (read from the `IMF_API_KEY` environment variable) unlocks wildcard
  queries on restricted databases.
* All examples that contact the API are wrapped in `\donttest{}`. All tests
  that contact the network use `skip_on_cran()` and `skip_if_offline()`.
