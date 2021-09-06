module BitqueryLogger
  module ErrorHandler
    def self.included(clazz)
      clazz.class_eval do
        rescue_from Exception, with: :log
      end
    end

    private
    def log(_e)

    end
  end
end