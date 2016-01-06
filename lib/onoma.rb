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
  NS_SEPARATOR = '-'

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
      @@set.nomenclature_names
    end

    def all
      @@set.nomenclatures
    end

    # Give access to named nomenclatures
    def [](name)
      @@set[name]
    end

    # Give access to named nomenclatures
    def find(*args)
      options = args.extract_options!
      name = args.shift
      if args.size == 0
        return @@set[name]
      elsif args.size == 1
        return @@set[name].find(args.shift) if @@set[name]
      end
      nil
    end

    def find_or_initialize(name)
      @@set[name] || Nomenclature.new(name, set: @@set)
    end

    # Browse all nomenclatures
    def each(&block)
      @@set.each(&block)
    end

    def load_database
      @@set = Database.open(reference_path)
      @database_loaded = true
      # Rails.logger.info 'Loaded nomenclatures: ' + Onoma.names.to_sentence
    end

    def database_loaded?
      @database_loaded
    end

    # Returns the matching nomenclature
    def const_missing(name)
      n = name.to_s.underscore.pluralize
      return self[n] if @@set.exist?(n)
      super
    end
  end
end
