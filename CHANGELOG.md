# Changelog

## [0.2.0]
### Changed
- Replaced the per-request `Thread.new` with a single long-lived background
  worker thread per middleware instance. Requests now compute the data
  point and push it onto a bounded, in-memory queue (never retaining the
  Rack `env` or response), and the worker thread continuously pops from
  that queue and performs the write. This avoids spawning and tearing down
  a thread (and the client/`WriteApi` it used to imply recreating) on every
  single request, which was the main source of the allocation and memory
  growth observed under load after upgrading to Ruby 3.4.
  - The worker thread is started lazily, on first request rather than in
    `initialize`, so this remains correct under Puma's `preload_app!`:
    threads don't survive `fork`, so each cluster worker process ends up
    creating (and owning) exactly one worker thread and queue of its own.
  - If InfluxDB is slow or unreachable, the queue fills up and further
    points are dropped instead of blocking requests or growing memory
    without bound.
  - Added `#shutdown`, called automatically on process exit, to close the
    queue and give the worker a brief chance to flush pending writes.
### Fixed
- Fixed a regression from 0.1.3 where every write raised
  `LocalJumpError: no block given (yield)`: the memoized client was created
  with `InfluxDB2::Client.use`, which requires a block and always yields to
  it. Switched to `InfluxDB2::Client.new`, since the client is now held for
  the lifetime of the middleware instead of being opened and closed per call.
- Stopped retaining the full Rack `env` and response inside the background
  write thread; the data point is now computed on the main thread before
  being handed off, and only that computed point is captured.

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
