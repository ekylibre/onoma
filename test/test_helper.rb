# frozen_string_literal: true

require_relative '../lib/onoma'

require 'active_support/core_ext/array/extract_options'

require 'minitest/autorun'

I18n.available_locales = %i[arb cmn deu eng fra ita jpn por spa]
Onoma.load_locales
Onoma.load!
