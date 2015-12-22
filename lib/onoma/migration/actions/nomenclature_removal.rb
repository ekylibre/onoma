module Onoma
  module Migration
    module Actions
      class NomenclatureRemoval < Onoma::Migration::Actions::Base
        attr_reader :nomenclature

        def initialize(element)
          @nomenclature = element['nomenclature']
          fail 'No given nomenclature' if @nomenclature.blank?
        end

        alias_method :name, :nomenclature

        def label
          "remove_nomenclature #{@name}"
        end

        def human_name
          "Remove nomenclature #{@name}"
        end
      end
    end
  end
end
