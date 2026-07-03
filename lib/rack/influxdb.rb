# frozen_string_literal: true

require 'influxdb-client'
require 'rack/influxdb/configuration'

module Rack
  # The InfluxDB rack middleware class.
  class InfluxDB
    # Caps how many computed points can be buffered while waiting to be
    # written. If InfluxDB becomes slow or unreachable, the queue fills up
    # and further points are dropped (see #enqueue) instead of growing
    # without bound or blocking requests.
    DEFAULT_QUEUE_SIZE = 1_000

    class << self
      def configuration
        @configuration ||= Rack::InfluxDB::Configuration.new
      end

      def configure
        yield(configuration)
      end
    end

    def initialize(app)
      @app = app
      @queue = SizedQueue.new(DEFAULT_QUEUE_SIZE)
      @worker_mutex = Mutex.new
      @worker = nil

      # Flush whatever is left in the queue when the process exits (e.g. on
      # a graceful Puma shutdown), so the last few requests before shutdown
      # aren't silently lost. This never blocks a request, only exit.
      at_exit { shutdown }
    end

    def call(env)
      @app.call(env).tap { |response| write_request(env, response) }
    end

    # Stops accepting new points and waits (briefly) for the worker to
    # drain whatever is already queued. Safe to call multiple times and
    # safe to call even if the worker was never started.
    def shutdown
      @queue.close unless @queue.closed?
      @worker&.join(5)
    end

    private

    def write_request(env, response)
      # The presence or absence of a token implicitly determines whether it
      # should be executed at all. This allows this gem to run in each
      # environment.
      return if config.token.to_s.empty?

      # Compute the point on the request thread so the queue - and the
      # worker that reads from it - never has to hold a reference to the
      # Rack env or response. Only the resulting Hash is handed off.
      enqueue(point(env, response))
    rescue StandardError => e
      # Let the app decide what needs to be done when an error occurs.
      config.handle_error.call(e)
    end

    # Rather than spawning a `Thread.new` (and a new client/WriteApi) for
    # every single request, requests push their computed point onto a
    # queue that a single long-lived worker thread drains. This avoids the
    # per-request cost of thread creation/teardown and the memory growth
    # that comes from many short-lived threads each closing over a Rack
    # env and response.
    def enqueue(data)
      start_worker
      # Non-blocking push: if the queue is full (InfluxDB is slow/down) we
      # drop the point instead of blocking the request or growing memory
      # without bound.
      @queue.push(data, true)
    rescue ClosedQueueError, ThreadError
      nil
    end

    # Lazily starts exactly one worker thread for this middleware instance.
    #
    # It's started lazily, on first request, rather than eagerly in
    # `initialize`, to stay correct under Puma's `preload_app!`: the app
    # (and this middleware) is built once in the master process, which
    # then fork()s a child process per cluster worker. OS threads do not
    # survive fork - only the forking thread continues to exist in the
    # child - so a thread started eagerly in `initialize` would already be
    # dead in every forked worker. Starting on first request instead means
    # each process (master or forked worker) creates its own worker thread
    # the first time it actually handles a request, so every worker
    # process naturally ends up owning exactly one live worker thread and
    # one queue.
    def start_worker
      return if @worker&.alive?

      @worker_mutex.synchronize do
        return if @worker&.alive?

        @worker = Thread.new { process_queue }
      end
    end

    # Runs on the single worker thread only. `client` and `write_api` are
    # therefore each created exactly once, lazily, with no need for extra
    # synchronization: nothing else ever touches them.
    def process_queue
      loop do
        data = @queue.pop
        # `pop` only returns nil once the queue has been closed (see
        # #shutdown) and fully drained, which is our signal to stop.
        break if data.nil?

        write_api.write(data: data)
      rescue StandardError => e
        config.handle_error.call(e)
      end
    end

    def point(env, response)
      {
        name: config.name,
        tags: config.tags,
        fields: config.fields.call(env, response)
      }
    end

    def write_api
      @write_api ||= client.create_write_api(write_options: config.write_options)
    end

    def client
      @client ||= InfluxDB2::Client.new(
        config.url, config.token, **config.options
      )
    end

    def config
      Rack::InfluxDB.configuration
    end
  end
end
