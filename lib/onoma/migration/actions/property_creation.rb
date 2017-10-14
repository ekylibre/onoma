module Onoma
  class Migration
    module Actions
      class PropertyCreation < Onoma::Migration::Actions::Base
        attr_reader :nomenclature, :name, :type, :options
        def initialize(element)
          name = element['property'].split('.')
          @nomenclature = name.first
          @name = name.second
          @type = element['type'].to_sym
          unless Property::TYPES.include?(@type)
            raise ArgumentError, "Property #{name} type is unknown: #{@type.inspect}"
          end
          @options = {}
          if element.has_attribute?('fallbacks')
            @options[:fallbacks] = element.attr('fallbacks').to_s.strip.split(/[[:space:]]*\,[[:space:]]*/).map(&:to_sym)
          end
          if element.has_attribute?('default')
            @options[:default] = element.attr('default').to_sym
          end
          @options[:required] = !!(element.attr('required').to_s == 'true')
          # @options[:inherit]  = !!(element.attr('inherit').to_s == 'true')
          if element.has_attribute?('choices')
            if type == :choice || type == :choice_list
              @options[:choices] = element.attr('choices').to_s.strip.split(/[[:space:]]*\,[[:space:]]*/).map(&:to_sym)
            elsif type == :item || type == :item_list
              @options[:choices] = element.attr('choices').to_s.strip.to_sym
            end
          end
        end

        def human_name
          updates = []
          updates << "#{@name} as name"
          @options.each do |k, v|
            updates << "#{v} as #{k}"
          end
          "Create property #{@nomenclature}.#{@name} with " + updates.to_sentence
        end
      end
    end
  end
end
