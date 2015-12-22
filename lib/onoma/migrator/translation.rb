module Onoma
  module Migrator
    class Translation
      def self.run(migration)
        puts "Migration #{migration.name}"
        I18n.available_locales.each do |locale|
          file = Onoma.root.join('config', 'locales', "#{locale}.yml")
          hash = Clean::Support.yaml_to_hash(file)
          migration.each_action do |action|
            ref = hash[locale.to_sym][:nomenclatures]
            ref[action.nomenclature.to_sym] ||= {}
            ref[action.nomenclature.to_sym][:items] ||= {}
            if action.is_a?(Onoma::Migration::Actions::ItemChange) && action.new_name?
              ref[action.nomenclature.to_sym][:items][action.new_name.to_sym] ||= ref[action.nomenclature.to_sym][:items].delete(action.name.to_sym)
            elsif action.is_a?(Onoma::Migration::Actions::ItemMerging)
              ref[action.nomenclature.to_sym][:items][action.into.to_sym] ||= ref[action.nomenclature.to_sym][:items].delete(action.name.to_sym)
            elsif action.is_a?(Onoma::Migration::Actions::NomenclatureChange) && action.changes[:name]
              ref[action.changes[:name].to_sym] = ref.delete(action.nomenclature.to_sym)
            elsif action.is_a?(Onoma::Migration::Actions::NomenclatureRemoval)
              ref.delete(action.nomenclature.to_sym)
            elsif !action.is_a?(Onoma::Migration::Actions::Base)
              fail "Cannot handle: #{action.inspect}"
            end
            File.write(file, Clean::Support.hash_to_yaml(hash))
          end
        end
      end
    end
  end
end
