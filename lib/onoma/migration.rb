class ::Hash

  def simple_print
    map { |k, v| "#{k}: #{v.inspect}" }.join(', ')
  end
  
end


require 'onoma/migration/actions'
require 'onoma/migration/base'
