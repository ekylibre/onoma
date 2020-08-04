module Onoma
  module Record
    class Base
      class << self
        def method_missing(*args, &block)
          Onoma.find_or_initialize(name.tableize.sub(/\Aonoma\//, '')).send(*args, &block)
        end

        def respond_to?(method_name)
          Onoma.find_or_initialize(name.tableize.sub(/\Aonoma\//, '')).respond_to?(method_name) || super
        end
      end
    end
  end
end
