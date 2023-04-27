# frozen_string_literal: true

require_relative "bitquery_logger/version"
require "logstash-logger"
require "exception_notification"
require "exception_notifier"
require "exception_notifier/rake"

module BitqueryLogger

  SERVER_NAME = Socket.gethostbyname(Socket.gethostname).first

  class Error < StandardError; end

  class Logger

    attr_reader :logger, :context

    def initialize(**kwargs)

      LogStashLogger.configure do |config|
        config.customize_event do |event|
          event.remove("@version")
          event.remove("host")
        end
      end

      case kwargs[:output]
      when :stdout

        @logger ||= LogStashLogger.new(
          type: :stdout,
          formatter: !!kwargs[:format_stdout] ? StdoutFormatter : ::Logger::Formatter
        )

        @logger.level = kwargs[:stdout_log_level] || 1

      when :stdout_json
        @logger ||= LogStashLogger.new(
          type: :stdout,
          formatter: JSONFormatter
        )

        @logger.level = kwargs[:stdout_log_level] || 1

      when :file

        @logger ||= LogStashLogger.new(
          type: :multi_logger,
          outputs: [{ type: :file,
                      path: kwargs[:path] || "log/elastic_#{Rails.env}.log",
                      formatter: JSONFormatter },
                    { type: :stdout,
                      formatter: !!kwargs[:format_stdout] ? StdoutFormatter : ::Logger::Formatter }]

        )

        # Set file logger log_level, default ERROR
        @logger.loggers[0].level = kwargs[:log_level] || 0
        # Set stdout logger log_level, default INFO
        @logger.loggers[1].level = kwargs[:stdout_log_level] || 1

      when :tcp

        @logger ||= LogStashLogger.new(
          type: :multi_logger,
          outputs: [{ type: :tcp,
                      host: kwargs[:host],
                      port: kwargs[:port],
                      buffer_max_items: kwargs[:buffer_max_items] || 50,
                      formatter: TcpFormatter },
                    { type: :stdout,
                      formatter: !!kwargs[:format_stdout] ? StdoutFormatter : ::Logger::Formatter }])

        # Set tcp logger log_level, default ERROR
        @logger.loggers[0].level = kwargs[:log_level] || 0
        # Set stdout logger log_level, default INFO
        @logger.loggers[1].level = kwargs[:stdout_log_level] || 1

      else
        raise ArgumentError.new 'No output selected'
      end

      ExceptionNotification.configure do |config|
        # Ignore additional exception types.
        # ActiveRecord::RecordNotFound, Mongoid::Errors::DocumentNotFound, AbstractController::ActionNotFound and ActionController::RoutingError are already added.
        # config.ignored_exceptions += %w{ActionView::TemplateError CustomError}

        # Adds a condition to decide when an exception must be ignored or not.
        # The ignore_if method can be invoked multiple times to add extra conditions.
        # config.ignore_if do |exception, options|
        # !Rails.env.production?
        # end

        # Ignore exceptions generated by crawlers
        # config.ignore_crawlers %w{Googlebot bingbot}

      end

      ExceptionNotifier::Rake.configure

      Rails.application.config.middleware.use ExceptionNotification::Rack,
                                              bitquery: {}

      Rails.application.config.middleware.use BitqueryLoggerMiddleware

    end

  end

  class JSONFormatter < ::Logger::Formatter
    def call(severity, time, progname, msg)
      BitqueryLogger.prepare_data(severity, time, msg).to_json+ "\n"
    end
  end

  class TcpFormatter < ::Logger::Formatter
    def call(severity, time, progname, msg)
      BitqueryLogger.prepare_data(severity, time, msg).to_json
    end
  end

  class StdoutFormatter < ::Logger::Formatter
    def call(severity, time, progname, msg)
      BitqueryLogger.prepare_data(severity, time, msg).to_s + "\n"
    end
  end

  class << self

    def init **kwargs

      @logger = Logger.new(**kwargs).logger
      @context = {}

    end

    def logger
      @logger
    end

    def purge_context
      @context = {}
    end

    def context
      @context
    end

    def extra_context ctx = {}, **kw_context
      @context.merge! ctx.merge kw_context
    end

    def set_env env
      @env = env
    end

    def env
      @env.presence || {}
    end

    def set_rake_task_details rake_task_details
      @rake_task_details = rake_task_details
    end

    def rake_task_details
      @rake_task_details.presence
    end

    def error msg, **ctx

      BitqueryLogger.extra_context **ctx

      @logger.error msg

    rescue => ex
      p ex
    end

    def warn msg, **ctx

      BitqueryLogger.extra_context **ctx

      @logger.warn msg

    rescue => ex
      p ex
    end

    def info msg, **ctx

      BitqueryLogger.extra_context **ctx

      @logger.info msg

    rescue => ex
      p ex
    end

    def debug msg, **ctx

      BitqueryLogger.extra_context **ctx

      @logger.debug msg

    rescue => ex
      p ex
    end

    def flush
      @logger.flush
    end

    def prepare_data severity, time, msg, **ctx
      # rack_env = BitqueryLogger.env.select { |k, v| v.is_a?(String) || v == !v }
      # env = ENV.to_hash

      # server_attributes: {
      #   'SERVER_NAME' => SERVER_NAME
      # },
      # env: {}.merge(
      #   env,
      #   rack_env,
      #   { 'PROCESS_ID' => $$,
      #     'THREAD_ID' => Thread.current.object_id }
      # ),

      m = {}

      m.merge!(rake: rake_task_details) if rake_task_details.present?
      m
        .merge!(BitqueryLogger.context.transform_values(&:to_s))
        .merge!(ctx)
        .merge!(
          {
            "@lvl" => severity,
            "@timestamp" => time.utc.strftime('%Y-%m-%dT%H:%M:%S.%LZ'),
            "@version" => BitqueryLogger::VERSION,
          }
        )
        .merge!(
          if msg.is_a? Exception
            { :message => msg.message,
              :backtrace => msg&.backtrace&.join("\n")
            }
          else
            { :message => msg }
          end
        )

      m

    end

  end

  class BitqueryLoggerMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      BitqueryLogger.purge_context
      BitqueryLogger.set_env env

      @app.call(env)

    end
  end

end

module ExceptionNotifier

  class BitqueryNotifier
    def initialize(options) end

    def call(exception, options = {})
      BitqueryLogger.error exception
    end

  end

end

module LogStashLogger

  class MultiLogger
    def error(progname = nil, &block)
      @loggers.each do |logger|
        logger.error(progname, &block) unless logger.formatter.instance_of? ::Logger::Formatter
      end
    end
  end

end
