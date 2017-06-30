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

    # # Returns version of DB
    # def reference_version
    #   return 0 unless reference_path.exist?
    #   reference_document.root['version'].to_i
    # end

    # def reference_document
    #   f = File.open(reference_path, 'rb')
    #   document = Nokogiri::XML(f) do |config|
    #     config.strict.nonet.noblanks.noent
    #   end
    #   f.close
    #   document
    # end

    def connection
      load_database unless database_loaded?
      @@set
    end

    # Returns the names of the nomenclatures
    def names
      set.nomenclature_names
    end

    def all
      set.nomenclatures
    end

    # Give access to named nomenclatures
    delegate :[], to: :set

    # Give access to named nomenclatures
    def find(*args)
      options = args.extract_options!
      name = args.shift
      if args.empty?
        return set[name]
      elsif args.size == 1
        return set[name].find(args.shift) if set[name]
      end
      nil
    end

    def find_or_initialize(name)
      set[name] || set.load_data_from_xml(name)
    end

    # Browse all nomenclatures
    def each(&block)
      set.each(&block)
    end

    def set
      @@set ||= NomenclatureSet.new
    end
  end
end
