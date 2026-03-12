# frozen_string_literal: true

require_relative "lib/jekyll-aeo/version"

Gem::Specification.new do |spec|
  spec.name          = "jekyll-aeo"
  spec.version       = JekyllAeo::VERSION
  spec.authors       = ["Manuel Gruber"]
  spec.summary       = "Answer Engine Optimization for Jekyll"
  spec.description   = "Generates clean markdown copies of Jekyll pages and llms.txt files for LLM consumption"
  spec.homepage      = "https://zaai.com/jekyll-aeo"
  spec.license       = "MIT"

  spec.metadata      = {
    "homepage_uri"    => spec.homepage,
    "source_code_uri" => "https://github.com/ZAAI-com/Jekyll-AEO",
    "bug_tracker_uri" => "https://github.com/ZAAI-com/Jekyll-AEO/issues"
  }

  spec.required_ruby_version = ">= 3.0"

  spec.files         = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "jekyll", ">= 4.0"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
end
