require 'test_helper'

class OnomaTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Onoma::VERSION
  end

  def test_it_does_something_useful
    assert ::Onoma
    assert !::Onoma.nomenclatures.empty?, 'Nomenclatures should be loaded'
    ::Onoma.nomenclatures.each do |n|
      item = n.items.values.first

      assert item, "Nomenclature #{n.name} has no items."

      I18n.available_locales = %i[eng fra]

      assert item.l(locale: :eng)
      assert item.l(locale: :fra)
    end
  end
end
