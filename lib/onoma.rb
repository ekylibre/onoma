require 'onoma/version'
require 'nokogiri'
require 'active_support/hash_with_indifferent_access'

require 'onoma/item'
require 'onoma/migration'
require 'onoma/nomenclature'
require 'onoma/database'
require 'onoma/property'
require 'onoma/reference'
require 'onoma/relation'
require 'onoma/reflection'
require 'pathname'

module Onoma
  XMLNS = 'http://www.ekylibre.org/XML/2013/nomenclatures'.freeze
  NS_SEPARATOR = '-'.freeze
  PROPERTY_TYPES = %i[boolean item item_list choice choice_list string_list date decimal integer nomenclature string symbol].freeze

  class MissingNomenclature < StandardError
  end

  class MissingChoices < StandardError
  end

  class InvalidProperty < StandardError
  end

  class << self
    def root
      Pathname.new(__FILE__).dirname.dirname
    end

    def database_path
      root.join('db')
    end

    def migrations_path
      database_path.join('migrate')
    end

    def reference_path
      database_path.join('reference.xml')
    end

    def connection
      load_database unless database_loaded?
      @@set
    end

    # Returns the names of the nomenclatures
    def names
      set.nomenclature_names
    end

    # Give access to named nomenclatures
    delegate :[], :nomenclatures, to: :set
    alias all nomenclatures

    # Give access to named nomenclatures
    def find(*args)
      args.extract_options!
      name = args.shift
      if args.empty?
        return set[name]
      elsif args.size == 1
        return set[name].find(args.shift) if set[name]
      end
      nil
    end

    # Browse all nomenclatures
    def each(&block)
      set.each(&block)
    end

    def set
      @@set ||= Database.open(reference_path)
    end
  end
end
