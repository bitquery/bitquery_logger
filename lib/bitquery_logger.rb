# frozen_string_literal: true

require_relative "bitquery_logger/version"
require "logstash-logger"

module BitqueryLogger

  # def included(clazz)
  #
  #   clazz.class_eval do
  #     rescue_from Exception, with: :log
  #   end
  #
  # end

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

      @logger ||= LogStashLogger.new type: type,
                                     host: host,
                                     port: port

    end

  end

  def self.logger args
    if @logger.present?
      @logger
    else
      @logger = Logger.new(args).logger
      @context = {}
    end

  end

  def self.context
    @context
  end

  def self.extra_context ctx
    @context.merge! ctx
  end

  def self.error msg
    @logger.error msg
  end

  def self.warn msg
    @logger.warn msg
  end

  def self.info msg
    @logger.info msg
  end

  def self.debug msg
    @logger.debug msg
  end

  private

  # def log(_e)
  #   @logger.info _e
  #
  #   raise _e
  # end

  # def self.new(**kwargs)
  #
  #   LogStashLogger.new kwargs
  #
  # end

  # class Logger
  #
  #   def initialize(type:,
  #                  host:,
  #                  port:)
  #
  #     LogStashLogger.new type: type,
  #                        host: host,
  #                        port: port
  #
  #   end
  #
  # end

end

module ExceptionNotifier

  SERVER_NAME = Socket.gethostbyname(Socket.gethostname).first

  class TcpNotifier
    def initialize(options)
      p 'initialize'
    end

    def call(exception, options = {})
      # p "call"
      # p exception, options

      BitqueryLogger.error LogStash::Event.new(prepare_data(exception, options))
    end

    private

    def prepare_data(exception, options)

      env = if (rake_command = options.dig(:data, :rake_command_line))
              { rake_command: rake_command }
            else
              options[:env].slice("env", "SCRIPT_NAME", "QUERY_STRING", "SERVER_PROTOCOL")
            end

      { message: exception,
        # stack_trace: exception.backtrace,
        server_attributes: {},
        env: env,
        context: BitqueryLogger.context }

    end

  end
end

# module Rake
#
#   class Task
#     alias_method :invoke_without_loggable, :invoke
#
#     def invoke(*args)
#       begin
#         invoke_without_loggable(*args)
#       rescue Exception => e
#         log(e)
#       end
#     end
#   end
#
# end
