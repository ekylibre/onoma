module Onoma
  # An item of a nomenclature is the core data.
  class Item
    attr_reader :nomenclature, :left, :right, :depth, :aliases, :parent_name
    attr_accessor :name, :attributes
    alias_method :properties, :attributes

    # New item
    def initialize(nomenclature, name, options = {})
      @nomenclature = nomenclature
      @name = name.to_s
      @left, @right = @nomenclature.new_boundaries
      @depth = 0
      parent = options.delete(:parent)
      if parent.is_a?(Symbol) || parent.is_a?(String)
        @parent_name = parent.to_s
      else
        self.parent = parent
      end
      @attributes = ActiveSupport::HashWithIndifferentAccess.new
      options.each do |k, v|
        set(k, v)
      end
    end

    def root?
      !parent
    end

    def parent=(item)
      old_parent_name = @parent_name
      if item.nil?
        @parent = nil
        @parent_name = nil
      else
        if item.is_a?(Symbol) || item.is_a?(String)
          item = nomenclature.find!(item.to_s)
        end
        if item.nomenclature != nomenclature
          fail 'Item must come from same nomenclature'
        end
        if item.parents.include?(self) || item == self
          fail 'Circular dependency. Item can be parent of itself.'
        end
        @parent = item
        @parent_name = @parent.name.to_s
      end
      @nomenclature.rebuild_tree! if old_parent_name != @parent_name
    end

    # Changes parent without rebuilding
    def parent_name=(name)
      @parent = nil
      @parent_name = name.to_s
    end

    def parent?
      parent.present?
    end

    def parent
      @parent ||= @nomenclature.find(@parent_name)
    end

    def original_nomenclature_name
      return parent.name.to_sym unless root?
      nil
    end

    # Returns children recursively by default
    def children(options = {})
      if options[:index].is_a?(FalseClass)
        if options[:recursively].is_a?(FalseClass)
          return nomenclature.list.select do |item|
            (item.parent == self)
          end
        else
          return children(index: false, recursive: false).each_with_object([]) do |item, list|
            list << item
            list += item.children(index: false, recursive: true)
            list
          end
        end
      else
        if options[:recursively].is_a?(FalseClass)
          return nomenclature.list.select do |item|
            @left < item.left && item.right < @right && item.depth == @depth + 1
          end
        else
          # @children ||=
          return nomenclature.list.select do |item|
            @left < item.left && item.right < @right
          end
        end
      end
    end

    def root
      self.parent? ? parent.root : self
    end

    # Returns direct parents from the closest to the farthest
    def parents
      @parents ||= (parent.nil? ? [] : [parent] + parent.parents)
    end

    def self_and_children(options = {})
      [self] + children(options)
    end

    def self_and_parents
      [self] + parents
    end

    # Computes left/right value for nested set
    # Returns right index
    def rebuild_tree!
      @nomenclature.forest_right = rebuild_tree(@nomenclature.forest_right + 1)
    end

    # Computes left/right value for nested set
    # Returns right index
    def rebuild_tree(left = 0, depth = 0)
      @depth = depth
      @left = left
      @right = @left + 1
      children(index: false, recursively: false).each do |child|
        @right = child.rebuild_tree(@right, @depth + 1) + 1
      end
      @right
    end

    # Returns true if the given item name match the current item or its children
    def include?(other)
      self >= other
    end

    # Return human name of item
    def human_name(options = {})
      "nomenclatures.#{nomenclature.name}.items.#{name}".t(options.merge(default: ["items.#{name}".to_sym, "enumerize.#{nomenclature.name}.#{name}".to_sym, "labels.#{name}".to_sym, name.humanize]))
    end
    alias_method :humanize, :human_name

    def human_notion_name(notion_name, options = {})
      "nomenclatures.#{nomenclature.name}.notions.#{notion_name}.#{name}".t(options.merge(default: ["labels.#{name}".to_sym]))
    end

    def ==(other)
      other = item_for_comparison(other)
      nomenclature == other.nomenclature && name == other.name
    end

    def <=>(other)
      other = item_for_comparison(other)
      nomenclature.name <=> other.nomenclature.name && name <=> other.name
    end

    def <(other)
      other = item_for_comparison(other)
      (other.left < @left && @right < other.right)
    end

    def >(other)
      other = item_for_comparison(other)
      (@left < other.left && other.right < @right)
    end

    def <=(other)
      other = item_for_comparison(other)
      (other.left <= @left && @right <= other.right)
    end

    def >=(other)
      other = item_for_comparison(other)
      (@left <= other.left && other.right <= @right)
    end

    def inspect
      "#{@nomenclature.name}-#{@name}(#{@left}-#{@right})"
    end

    def tree(depth = 0)
      text = "#{left.to_s.rjust(4)}-#{right.to_s.ljust(4)} #{'  ' * depth}#{@name}:\n"
      text << children(index: false, recursively: false).collect do |c|
        c.tree(depth + 1)
      end.join("\n")
      text
    end

    def to_xml_attrs
      attrs = {}
      attrs[:name] = name
      attrs[:parent] = @parent_name if self.parent?
      properties.each do |pname, pvalue|
        if p = nomenclature.properties[pname.to_s]
          if p.type == :decimal
            pvalue = pvalue.to_s.to_f
          elsif p.list?
            pvalue = pvalue.join(', ')
          end
        end
        attrs[pname] = pvalue.to_s
      end
      attrs
    end

    # Returns property value
    def property(name)
      property = @nomenclature.properties[name]
      value = @attributes[name]
      if property
        if value.nil? && property.fallbacks
          for fallback in property.fallbacks
            value ||= @attributes[fallback]
            break if value
          end
        end
        value ||= cast_property(name, property.default) if property.default
      end
      value
    end

    def selection(name)
      property = @nomenclature.properties[name]
      if property.list?
        return property(name).collect do |i|
          ["nomenclatures.#{@nomenclature.name}.item_lists.#{self.name}.#{name}.#{i}".t, i]
        end
      elsif property.nomenclature?
        return Onoma[property(name)].list.collect do |i|
          [i.human_name, i.name]
        end
      else
        fail StandardError, 'Cannot call selection for a non-list property'
      end
    end

    # Checks if item has property with given name
    def has_property?(name)
      !@nomenclature.properties[name].nil?
    end

    # Returns property descriptor
    def method_missing(method_name, *args)
      return property(method_name) if has_property?(method_name)
      super
    end

    def set(name, value)
      fail "Invalid property: #{name.inspect}" if [:name, :parent].include?(name.to_sym)
      # TODO: check format
      if property = nomenclature.properties[name]
        value ||= [] if property.list?
      end
      @attributes[name] = value
    end

    private

    def cast_property(name, value)
      @nomenclature.cast_property(name, value)
    end

    def item_for_comparison(other)
      item = nomenclature[other.is_a?(Item) ? other.name : other]
      unless item
        fail StandardError, "Invalid operand to compare: #{other.inspect} not in #{nomenclature.name}"
      end
      item
    end
  end
end
