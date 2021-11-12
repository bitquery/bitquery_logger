# frozen_string_literal: true

require_relative "bitquery_logger/version"
require "logstash-logger"

module BitqueryLogger

  SERVER_NAME = Socket.gethostbyname(Socket.gethostname).first

  class Error < StandardError; end

  class Logger

    attr_reader :logger, :context

    def initialize(**kwargs)

      config = LogStashLogger.configure do |config|
        config.customize_event do |event|
          event.remove("@version")
          event.remove("host")
        end
      end

      if !kwargs[:log_to_console]

        @logger ||= LogStashLogger.new(
          type: :multi_logger,
          outputs: [{ type: kwargs[:type],
                      host: kwargs[:host],
                      port: kwargs[:port],
                      buffer_max_items: kwargs[:buffer_max_items] || 50,
                      formatter: TcpFormatter },
                    { type: :stdout,
                      formatter: ::Logger::Formatter  }])

        # Set tcp logger log_level, default ERROR
        @logger.loggers[0].level = kwargs[:tcp_log_level] || 3
        # Set stdout logger log_level, default INFO
        @logger.loggers[1].level = kwargs[:stdout_log_level] || 1

      else

        @logger ||= LogStashLogger.new(type: :stdout,
                                       formatter: ::Logger::Formatter)

        # Set stdout logger log_level, default INFO
        @logger.level = kwargs[:stdout_log_level] || 1

      end

    end

  end

  class TcpFormatter < ::Logger::Formatter

    def call(severity, time, progname, msg)

      additional_data = {
        "@timestamp" => time.strftime('%Y-%m-%dT%H:%M:%S.%L'),
        "severity" => severity,
        "version" => BitqueryLogger::VERSION
      }

      BitqueryLogger.prepare_data(msg).merge(additional_data).to_json

    end

  end

  class << self

    def init **kwargs

      @log_to_console = !!kwargs[:log_to_console]
      @logger = Logger.new(**kwargs).logger
      @context = {}

    end

    def logger
      @logger
    end

    def context
      @context
    end

    def extra_context ctx
      @context.merge! ctx
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

    end

    def warn msg, **ctx

      BitqueryLogger.extra_context **ctx

      @logger.warn msg

    end

    def info msg, **ctx

      BitqueryLogger.extra_context **ctx

      @logger.info msg

    end

    def debug msg, **ctx

      BitqueryLogger.extra_context **ctx

      @logger.debug msg

    end

    def flush
      @logger.flush
    end

    def prepare_data msg, **ctx

      rack_env = BitqueryLogger.env.select { |k, v| v.is_a?(String) || v == !v }
      env = ENV.to_hash

      BitqueryLogger.extra_context ctx

      message = if msg.is_a? Exception
                  { message: msg.message,
                    backtrace: msg&.backtrace&.join("\n")
                  }
                else
                  { message: msg }
                end

      message.merge!(context: BitqueryLogger.context,
                     server_attributes: {
                       'SERVER_NAME' => SERVER_NAME
                     },
                     env: {}.merge(
                       env,
                       rack_env,
                       { 'PROCESS_ID' => $$,
                         'THREAD_ID' => Thread.current.object_id }
                     ),
      )

      message.merge!(rake: rake_task_details) if rake_task_details.present?

      message

    end

  end

  class BitqueryLoggerMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)

      BitqueryLogger.set_env env

      @app.call(env)

    end
  end

end

module ExceptionNotifier

  class TcpNotifier
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
