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

    def logger args
      if @logger.present?
        @logger
      else
        @logger = Logger.new(args).logger
        @context = {}
      end

    end

    def context
      @context
    end

    def extra_context ctx
      @context.merge! ctx
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

    private

    def prepare_data msg

      # env = if (rake_command = options.dig(:data, :rake_command_line))
      #         { rake_command: rake_command }
      #       else
      #         options[:env].slice("env", "SCRIPT_NAME", "QUERY_STRING", "SERVER_PROTOCOL")
      #       end

      message = if msg.is_a? Exception
                  { message: msg.message,
                    backtrace: msg.backtrace }
                else
                  { message: msg }
                end

      message.merge(context: BitqueryLogger.context,
                    server_attributes: {
                      server_name: SERVER_NAME
                    },
      # env: env,
      )

    end

  end

end

module ExceptionNotifier

  class TcpNotifier
    def initialize(options)
      ;
    end

    def call(exception, options = {})

      BitqueryLogger.error exception

    end

  end

end

