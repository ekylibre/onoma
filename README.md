# Onoma

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/onoma`.

To experiment with that code, run `bin/console` for an interactive prompt.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'onoma'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install onoma

## Usage

In your Ekylibre project adds the gem in your `Gemfile` and use it like example:

```ruby
n = Onoma::Molecule            # Returns an Onoma::Nomenclature object
n.human_name                   # Returns translation in current locale of the nomenclature
n.properties                   # Returns the array of properties of the nomenclature

i = n.find(:dinitrogen)            # Returns an Onoma::Item object
i.human_name                   # Returns translation in current locale of the item
i.formula                      # Returns property 'formula' defined in nomenclatures for given item
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

```ruby
# load nomenclatures
Onoma.load!
# return all items of the units nomenclature
Onoma::Unit.all
# find the net_surface_area item in the units nomenclature
i = Onoma::Unit[:kilogram]
# find dimension of the unit kilogram
i.dimension
# => :mass
```

To install this gem onto your local machine, run `bundle exec rake install`.

To add more items, you can add migration in db/migrate folder and then run `bin/rake db:migrate`

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ekylibre/onoma. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
