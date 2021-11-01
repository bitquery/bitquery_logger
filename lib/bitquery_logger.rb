# frozen_string_literal: true

require_relative "bitquery_logger/version"
require "logstash-logger"

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

      if !kwargs[:log_to_console]
        @logger ||= LogStashLogger.new(
          type: :multi_delegator,
          outputs: [{ type: kwargs[:type],
                      host: kwargs[:host],
                      port: kwargs[:port] },
                    { type: :stdout }])
      else
        @logger = ::Logger.new(STDOUT)
      end

    end

  end

  class << self

    def init **kwargs

      @development = !!kwargs[:log_to_console]
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

    def error msg, **extra_context
      return if @development
      @logger.error prepare_data msg, **extra_context
    end

    def warn msg, **extra_context
      if @development
        puts msg
        return
      end

      @logger.warn prepare_data msg, **extra_ccontext
    end

    def info msg, **extra_context
      if @development
        puts msg
        return
      end

      @logger.info prepare_data msg, **extra_ccontext
    end

    def debug msg, **extra_context
      if @development
        puts msg
        return
      end

      @logger.debug prepare_data msg, **extra_ccontext
    end

    def flush
      @logger.flush
    end

    private

    def prepare_data msg, **extra_context

      rack_env = BitqueryLogger.env.select { |k, v| v.is_a?(String) || v == !v }
      env = ENV.to_hash

      BitqueryLogger.extra_context extra_context

      message = if msg.is_a? Exception
                  { message: msg.message,
                    backtrace: msg.backtrace.join("\n")
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

