# frozen_string_literal: true

require_relative "bitquery_logger/version"
require "logstash-logger"

module BitqueryLogger

  SERVER_NAME = Socket.gethostbyname(Socket.gethostname).first

  class Error < StandardError; end

  class Logger

    attr_reader :logger, :context

    def initialize(type:,
                   host:,
                   port:)

      LogStashLogger.configure do |config|
        config.customize_event do |event|
          event.remove("@version")
          event.remove("host")
        end
      end

      # @logger ||= if !Rails.env.development?
      #               LogStashLogger.new type: type,
      #                                  host: host,
      #                                  port: port
      #             else
      #               ::Logger.new(STDOUT)
      #             end

      @logger ||= LogStashLogger.new type: type,
                                     host: host,
                                     port: port

    end

  end

  class << self

    def init args

      @logger = Logger.new(args).logger
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

    def error msg
      @logger.error prepare_data msg
    end

    def warn msg
      @logger.warn prepare_data msg
    end

    def info msg
      @logger.info prepare_data msg
    end

    def debug msg
      @logger.debug prepare_data msg
    end

    def flush
      @logger.flush
    end

    private

    def prepare_data msg

      rack_env = BitqueryLogger.env.select { |k, v| v.is_a?(String) || v == !v }
      env = ENV.to_hash

      message = if msg.is_a? Exception
                  { message: msg.message,
                    backtrace: msg.backtrace }
                else
                  { message: msg }
                end

      message.merge(context: BitqueryLogger.context,
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

