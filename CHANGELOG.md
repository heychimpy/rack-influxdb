# Changelog

## [0.1.3]
### Fixed
- Fixed a race condition where concurrent requests during the first write
  could each lazily create their own InfluxDB client and `WriteApi`
  (each spinning up its own background batch processor); the client and
  write API are now only ever initialized once, under a mutex.

## [0.1.2]
### Fixed
- Fixed a regression from 0.1.1 where request data was never actually
  written to InfluxDB: the write logic was passed as a block to a method
  that never yielded, so it silently never ran.
- Stopped creating a new `WriteApi` (and its background batch processor)
  on every request; the write API client is now created once and reused.

## [0.1.1]
### Added
- Added a code of conduct.
- Added a changelog.
- Added Rubocop check.
- Added Reek check.
- Added Brakeman check.

## [0.1.0] - Initial Commits
- Added initial configuration and path settings.
- Added error handling and write options.
- Added `.github/workflows/test.yml` for continuous integration.
- Improved specs for the project.
- Moved writing to a separate thread.
- Switched to RSpec from Minitest.
- Improved `README.md`.
- Removed support for Ruby 2.6.
- Added support for Linux `x86_64` architecture.
- Added minimal tests.
