module Onoma
  module Migrator
    class Reference
      def self.run(migration)
        ref = new
        migration.each_action do |action|
          ref.send(action.action_name, action)
        end
        ref.version = migration.number
        puts "Write DB in #{Onoma.reference_path.relative_path_from(Onoma.root)}"
        ref.write
      end

      def initialize
        @set = if Onoma.reference_path.exist?
                 Onoma::NomenclatureSet.load_file(Onoma.reference_path)
               else
                 Onoma::NomenclatureSet.new
               end
      end

      def version
        @set.version
      end

      def version=(number)
        @set.version = number
      end

      def write
        File.write(Onoma.reference_path, @set.to_xml)
      end

      def nomenclature_creation(action)
        @set.add_nomenclature(action.name, action.options)
      end

      def nomenclature_change(action)
        @set.change_nomenclature(action.nomenclature, action.changes)
      end

      def nomenclature_removal(action)
        @set.remove_nomenclature(action.nomenclature)
      end

      def property_creation(action)
        @set.add_property(action.nomenclature, action.name, action.type, action.options)
      end

      def property_change(action)
        @set.change_property(action.nomenclature, action.name, action.changes)
      end

      def item_creation(action)
        @set.add_item(action.nomenclature, action.name, action.options)
      end

      def item_change(action)
        @set.change_item(action.nomenclature, action.name, action.changes)
      end

      def item_merging(action)
        @set.merge_item(action.nomenclature, action.name, action.into)
      end

      def item_removal(action)
        @set.remove_item(action.nomenclature, action.name)
      end
    end
  end
end
