require 'active_support/core_ext/string'
require 'active_support/core_ext/array'
require 'benchmark'

class ::Hash
  def simple_print
    map { |k, v| "#{k}: #{v.inspect}" }.join(', ')
  end
end

module Onoma
  # Migration instance represents a migration file
  class Migration
    class << self
      # Parse en XML migration to a Onoma::Migration object
      def parse(file)
        # puts "Parse #{file}"
        f = File.open(file, 'rb')
        document = Nokogiri::XML(f) do |config|
          config.strict.nonet.noblanks.noent
        end
        f.close
        root = document.root
        number = file.basename.to_s.split('_').first.to_i
        new(number, root['name']) do |m|
          root.children.each do |child|
            next unless child.is_a? Nokogiri::XML::Element
            m.add "Onoma::Migration::Actions::#{child.name.underscore.classify}".constantize.new(child)
          end
        end
      end
    end

    attr_reader :number, :name

    def initialize(number, name)
      @number = number
      @name = name
      @actions = []
      yield self if block_given?
    end

    def label
      "#{number} #{name}"
    end

    def add(action)
      @actions << action
    end

    def each_action(&block)
      @actions.each(&block)
    end

    def inspect
      "#<#{self.class.name}:#{sprintf('%#x', object_id)} ##{number} #{name.inspect} (#{@actions.size} actions)>"
    end

    def migrate(conn)
      puts ''
      puts "== #{label}: migrating ".ljust(80, '=')
      duration = Benchmark.measure do
        each_action do |action|
          puts "-- #{action.label}"
          conn.exec_action(action)
        end
        conn.version = number
      end
      puts "== #{label}: migrated (#{duration.real.round(4)}s)".ljust(80, '=')
      # puts "Write DB in #{Onoma.reference_path.relative_path_from(Onoma.root)}".yellow
      versions_dir = Onoma.root.join('tmp', 'versions')
      FileUtils.mkdir_p(versions_dir)
      conn.copy(versions_dir.join("#{number}.xml"))
    end
  end

  # Migrator is a tool class to launch migrations
  class Migrator
    class << self
      def migrate
        Onoma::Migrator.new(Onoma.reference_path, Onoma.migrations_path).migrate
      end
    end

    attr_accessor :database_path, :migrations_path

    def initialize(database_path, migrations_path)
      @database_path = database_path
      @migrations_path = migrations_path
    end

    # Returns list of Onoma::Migration
    def migrations
      Dir.glob(@migrations_path.join('*.xml')).sort.collect do |f|
        Onoma::Migration.parse(Pathname.new(f))
      end
    end

    # Returns list of migrations since last done
    def missing_migrations
      last_version = connection.version
      migrations.select do |m|
        m.number > last_version
      end
    end

    def migrate
      missing_migrations.each do |migration|
        migration.migrate(connection)
      end
      connection.write
    end

    def connection
      @connection ||= Database.open(@database_path)
    end
  end
end

require 'onoma/migration/actions'
