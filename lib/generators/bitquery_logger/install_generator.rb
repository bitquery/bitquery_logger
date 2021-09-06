module BitqueryLogger
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc 'Creates a BitqueryLogger initializer.'

      source_root File.expand_path(__dir__)

      def copy_initializer
        copy_file 'bitquery_logger.rb', 'config/initializers/bitquery_logger.rb'
      end
    end
  end
end