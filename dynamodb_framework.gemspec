# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dynamodb_framework/version'

Gem::Specification.new do |spec|
  spec.name          = "dynamodb_framework"
  spec.version       = DynamodbFramework::VERSION
  spec.authors       = ["vaughanbrittonsage"]
  spec.email         = ["vaughanbritton@gmail.com"]

  spec.summary       = 'A lightweight framework to provide managers for working with aws dynamodb (incuding local version).'
  spec.description   = 'A lightweight framework to provide managers for working with aws dynamodb (incuding local version).'
  spec.homepage      = "https://github.com/vaughanbrittonsage/dynamodb_framework"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency('json')
  spec.add_dependency('aws-sdk-core')

end
