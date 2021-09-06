# frozen_string_literal: true

require_relative "lib/bitquery_logger/version"

Gem::Specification.new do |spec|
  spec.name          = "bitquery_logger"
  spec.version       = BitqueryLogger::VERSION
  spec.authors       = ["Andrey Ivanov"]
  spec.email         = ["ivanov17andrey@gmail.com"]

  spec.summary       = "Bitquery Logger"
  spec.description   = "Bitquery Logger"
  spec.homepage      = "https://github.com/bitquery/bitquery_logger.git"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bitquery/bitquery_logger.git"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "exception_notification"
  spec.add_dependency "exception_notification-rake", "~> 0.3.1"
  spec.add_dependency "logstash-logger", "~> 0.26.1"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
