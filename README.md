# Em::Dextras
Utilities to help working with EventMachine Deferrables. Includes probes for
asynchronous tests and a DSL to chain deferrables.

## Installation

Add this line to your application's Gemfile:

    gem 'em-dextras'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install em-dextras

## Usage

Documentation is currently lacking, fixing this is our number 1 priority.

The project offers:
 * A DSL to structure asynchronous computations, inspired by [SoundCloud empipelines](https://github.com/soundcloud/empipelines)
   and [future composition](http://code.technically.us/post/17965128229/fables-of-the-reconstruction-part-3-leibniz-saw-all)
 * Methods to help test deferrable based code
   - Low-level probing 
   - Syntatic sugar as RSpec matchers


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
