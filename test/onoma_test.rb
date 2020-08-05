# coding: utf-8
require 'test_helper'

class OnomaTest < Minitest::Test
  def test_models_are_loadable
    assert Onoma::Record::Base
    assert Onoma::Unit
  end

  def test_that_it_has_a_version_number
    refute_nil ::Onoma::VERSION
  end

  def test_it_does_something_useful
    assert ::Onoma
    refute ::Onoma.all.empty?, 'Nomenclatures should be loaded'
    ::Onoma.all.each do |n|
      item = n.items.values.first
      assert item, "Nomenclature #{n.name} has no items."
    end
  end

  def test_i18n
    nomenclature = Onoma.find(:countries)
    assert_equal 'Pays', nomenclature.human_name(locale: :fra)
    assert_equal 'Countries', nomenclature.human_name(locale: :eng)
    item = nomenclature[:ae]
    refute_nil item
    assert_equal 'Émirats Arabes Unis', item.l(locale: :fra)
    assert_equal 'United Arab Emirates', item.l(locale: :eng)
  end
end
