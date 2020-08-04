require 'bundler/gem_tasks'
require 'rake/testtask'
require 'onoma'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

task default: :test

namespace :db do
  task :list do
    Onoma.all.each do |n|
      if n.name.to_s.classify.tableize != n.name.to_s
        puts n.name.to_s.red
      else
        puts n.name
      end
    end
  end

  namespace :export do
    desc 'Export nomenclatures as CSV in tmp/nomenclatures'
    task :csv do
      output = Onoma.root.join('tmp', 'nomenclatures')
      FileUtils.rm_rf(output)
      FileUtils.mkdir_p(output)
      Onoma.all.each do |n|
        n.to_csv(output.join("#{n.name}.csv"))
      end
    end
  end

  task export: 'export:csv'

  namespace :migrate do
    task :generate do
      unless name = ENV['NAME']
        puts 'Use command with NAME: rake onoma:migrate:generate NAME=add_some_stuff'
        exit 1
      end
      name = name.downcase.gsub(/[\s\-\_]+/, '_')
      full_name = Time.zone.now.l(format: '%Y%m%d%H%M%S') + "_#{name}"
      file = Onoma.root.join('db', 'migrate', "#{full_name}.xml")
      found = Dir.glob(Onoma.migrations_path.join('*.xml')).detect do |file|
        File.basename(file).to_s =~ /^\d+\_#{name}\.xml/
      end
      if found
        puts "A migration with same name #{name} already exists: #{Pathname.new(found).relative_path_from(Onoma.root)}"
        exit 2
      end
      xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
      xml << "<migration name=\"#{name.humanize}\">\n"
      xml << "  <!-- Add your changes here -->\n"
      xml << "</migration>\n"
      File.write(file, xml)
      puts "Create #{file.relative_path_from(Onoma.root).to_s.yellow}"
    end

    task :translation do
      Onoma.missing_migrations.each do |migration|
        Onoma::Migrator::Translation.run(migration)
      end
    end

    task :reference do
      Onoma.missing_migrations.each do |migration|
        Onoma::Migrator::Reference.run(migration)
      end
    end
  end

  desc 'Migrates data'
  task :migrate do
    I18n.available_locales = %i[eng fra]

    Onoma::load_locales
    Onoma::Migrator.migrate
  end

  # task migrate: 'migrate:reference'
  # task :migrate do
  #   Onoma.missing_migrations.each do |migration|
  #     puts migration.name.yellow
  #     Onoma::Migrator::Reference.run(migration)
  #     Onoma::Migrator::Model.run(migration)
  #     Onoma::Migrator::Translation.run(migration)
  #   end
  # end
end
