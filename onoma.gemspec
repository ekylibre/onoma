
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'onoma/version'

Gem::Specification.new do |spec|
  spec.name          = 'onoma'
  spec.version       = Onoma::VERSION
  spec.authors       = ['Brice TEXIER']
  spec.email         = ['brice@ekylibre.com']

  spec.summary       = 'Provides open nomenclature data in a gem'
  spec.description   = 'Actual support Open-Nomenclature data and gem for use'
  spec.homepage      = 'https://github.com/ekylibre/onoma'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.17.3'
  spec.add_development_dependency 'colored'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'i18n-tasks'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'nokogiri', '~> 1.8.1'
end
