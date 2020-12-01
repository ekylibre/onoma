# frozen_string_literal: true

require_relative '../lib/onoma'

require 'minitest/autorun'

I18n.available_locales = %i[arb cmn deu eng fra ita jpn por spa]
Onoma.load_locales
Onoma.load!
