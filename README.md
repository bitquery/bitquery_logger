# BitqueryLogger

## Installation

Add this line to your application's Gemfile:

```ruby
# Logger
gem 'bitquery_logger', git: 'https://github.com/bitquery/bitquery_logger.git', branch: 'main'#, path: '../bitquery_logger'
```

And then execute:

    $ bundle install

Execute

    $ rails g bitquery_logger:install

to add initializer

And add to `environments/[env].rb`

```ruby
BITQUERY_LOGGER_CONFIG = {
  output: :file,
  log_level: 0
}
```

Possible settings

```ruby
BITQUERY_LOGGER_CONFIG = {
  # Uncomment to 'disable' logger
  # output: :stdout,
  # format_stdout: false,
  
  output: :tcp,
  host: "127.0.0.1",
  port: 5170,
  buffer_max_items: 300,
  log_level: 2,
  # output: :stdout
  # stdout_log_level: 0,
  # format_stdout: true
}
```

## Usage

Automatic exception dispatch already works

To send message with some level use

```ruby
BitqueryLogger.debug msg
BitqueryLogger.info msg
BitqueryLogger.warn msg
BitqueryLogger.error msg
```

`msg` can be String or Hash

To add to context use:

```ruby
BitqueryLogger.extra_context hash
```

To flush buffer use: 

```ruby
BitqueryLogger.flush
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/bitquery_logger. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/bitquery_logger/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the BitqueryLogger project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/bitquery_logger/blob/main/CODE_OF_CONDUCT.md).
