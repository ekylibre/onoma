module Onoma
  module Migration
    module Actions
      class NomenclatureCreation < Onoma::Migration::Actions::Base
        attr_reader :nomenclature, :options

        def initialize(element)
          @nomenclature = element.key?('nomenclature') ? element['nomenclature'].to_s : element.key?('name') ? element['name'].to_s : nil
          fail 'No given name' unless @nomenclature
          @options = {}
          notions = element.attr('notions').to_s.split(/\s*\,\s*/).map(&:to_sym)
          @options[:notions] = notions if notions.any?
          @options[:translateable] = !(element.attr('translateable').to_s == 'false')
        end

        alias_method :name, :nomenclature

        def human_name
          "Create nomenclature #{@name}"
        end
      end
    end
  end
end
