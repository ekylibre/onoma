module Onoma
  # This class represents a set of nomenclature like the reference DB
  class Database
    attr_accessor :version
    attr_reader :path

    def initialize(path)
      @path = Pathname.new(path)
      @nomenclatures = ActiveSupport::HashWithIndifferentAccess.new
      @version = 0
    end

    def self.open(path)
      db = new(path)
      db.parse_file(path) if path.exist?
      db
    end

    def write
      File.write(@path, to_xml)
    end

    def copy(path)
      File.write(path, to_xml)
    end
    
    def nomenclature_names
      @nomenclatures.keys
    end

    def nomenclatures
      @nomenclatures.values
    end

    # Find nomenclature
    def [](nomenclature_name)
      @nomenclatures[nomenclature_name]
    end
    alias_method :find, :[]
    alias_method :nomenclature, :[]

    # Find item
    def item(nomenclature_name, item_name)
      nomenclature = find!(nomenclature_name)
      nomenclature.item(item_name)
    end

    # Find property
    def property(nomenclature_name, property_name)
      nomenclature = find!(nomenclature_name)
      nomenclature.property(property_name)
    end

    def find!(name)
      unless nomenclature = @nomenclatures[name]
        fail "Nomenclature #{name} does not exist"
      end
      nomenclature
    end

    def exist?(name)
      @nomenclatures[name].present?
    end

    def each(&block)
      if block.arity == 2
        @nomenclatures.each(&block)
      else
        nomenclatures.each(&block)
      end
    end

    # Returns references between nomenclatures
    def references
      list = []
      each do |nomenclature|
        list += nomenclature.references
      end
      list
    end

    def to_xml
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.nomenclatures(xmlns: Onoma::XMLNS, version: @version) do
          @nomenclatures.values.sort.each do |nomenclature|
            xml.nomenclature(nomenclature.to_xml_attrs) do
              xml.properties do
                nomenclature.properties.values.sort.each do |property|
                  xml.property(property.to_xml_attrs)
                end
              end if nomenclature.properties.any?
              xml.items do
                nomenclature.items.values.sort { |a, b| a.name <=> b.name }.each do |item|
                  xml.item(item.to_xml_attrs)
                end
              end if nomenclature.items.any?
            end
          end
        end
      end
      builder.to_xml
    end

    def exec_action(action)
      case action.action_name.to_sym
      when :nomenclature_creation
        add_nomenclature(action.name, action.options)
      when :nomenclature_change
        change_nomenclature(action.nomenclature, action.changes)
      when :nomenclature_removal
        remove_nomenclature(action.nomenclature)
      when :property_creation
        add_property(action.nomenclature, action.name, action.type, action.options)
      when :property_change
        add_property(action.nomenclature, action.name, action.changes)
      when :item_creation
        add_item(action.nomenclature, action.name, action.options)
      when :item_change
        change_item(action.nomenclature, action.name, action.changes)
      when :item_merging
        merge_item(action.nomenclature, action.name, action.into)
      when :item_removal
        remove_item(action.nomenclature, action.name)
      else
        fail "Unknown action: #{action.action_name}"
      end
    end

    def add_nomenclature(name, options = {})
      fail "Nomenclature #{name} already exists" if @nomenclatures[name]
      options[:set] = self
      @nomenclatures[name] = Nomenclature.new(name, options)
    end

    def move_nomenclature(old_name, new_name)
      unless @nomenclatures[old_name]
        fail "Nomenclature #{old_name} does not exist"
      end
      fail "Nomenclature #{new_name} already exists" if @nomenclatures[new_name]
      @nomenclatures[new_name] = @nomenclatures.delete(old_name)
      @nomenclatures[new_name]
    end

    def change_nomenclature(nomenclature_name, updates = {})
      nomenclature = find!(nomenclature_name)
      nomenclature.update_attributes(updates)
      if updates[:name]
        nomenclature = move_nomenclature(nomenclature_name, updates[:name])
      end
      nomenclature
    end

    def remove_nomenclature(nomenclature_name)
      nomenclature = find!(nomenclature_name)
      @nomenclatures.delete(nomenclature_name)
    end

    def add_property(nomenclature_name, property_name, type, options = {})
      nomenclature = find!(nomenclature_name)
      nomenclature.add_property(property_name, type, options)
    end

    def change_property(_nomenclature_name, _property_name, _updates = {})
      fail NotImplementedError
    end

    def remove_property(_nomenclature_name, _property_name, _options = {})
      fail NotImplementedError
    end

    def add_item(nomenclature_name, item_name, options = {})
      nomenclature = find!(nomenclature_name)
      options = nomenclature.cast_options(options)
      nomenclature.add_item(item_name, options)
    end

    def change_item(nomenclature_name, item_name, updates = {})
      nomenclature = find!(nomenclature_name)
      updates = nomenclature.cast_options(updates)
      nomenclature.change_item(item_name, updates)
    end

    def merge_item(nomenclature_name, item_name, into)
      nomenclature = find!(nomenclature_name)
      nomenclature.merge_item(item_name, into)
    end

    def remove_item(nomenclature_name, item_name)
      nomenclature = find!(nomenclature_name)
      nomenclature.remove_item(item_name)
    end

    protected

    def harvest_nomenclature(element)
      nomenclature = Nomenclature.harvest(element, set: self)
      @nomenclatures[nomenclature.name] = nomenclature
    end

    def parse_file(file)
      f = File.open(file, 'rb')
      document = Nokogiri::XML(f) do |config|
        config.strict.nonet.noblanks.noent
      end
      f.close
      document.root.children.each do |nomenclature|
        harvest_nomenclature(nomenclature)
      end
      version = document.root['version'].to_i
    end
  end
end
