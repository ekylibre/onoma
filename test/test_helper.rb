$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'onoma'

require 'minitest/autorun'

I18n.available_locales = %i[arb cmn deu eng fra ita jpn por spa]
Onoma.load_locales
