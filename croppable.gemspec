require_relative "lib/croppable/version"

Gem::Specification.new do |spec|
  spec.name        = "croppable"
  spec.version     = Croppable::VERSION
  spec.authors     = ["Steven Barragán Naranjo"]
  spec.email       = ["me@steven.mx"]
  spec.homepage    = "https://github.com/stevenbarragan/croppable"
  spec.summary     = "Easily crop images in Ruby on Rails with Cropper.js integration"
  spec.license     = "MIT"
  
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/stevenbarragan/croppable"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib,javascripts}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7"
  spec.add_dependency "image_processing", "~> 1.2"
end
