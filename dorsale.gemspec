# encoding: utf-8
$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "dorsale/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "dorsale"
  s.version     = Dorsale::VERSION
  s.authors     = ["agilidée"]
  s.email       = ["contact@agilidee.com"]
  s.homepage    = "https://github.com/agilidee/dorsale"
  s.summary     = "Modular ERP made with Ruby on Rails"
  s.description = "Run your own business."
  s.test_files = Dir["spec/**/*"]

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", ">= 4.0.0"
  s.add_dependency "slim-rails"
  s.add_dependency "sass-rails"
  s.add_dependency "bootstrap-sass"
  s.add_dependency "font-awesome-sass"
  s.add_dependency "simple_form"
  s.add_dependency "coffee-rails"
  s.add_dependency "jquery-rails"
  s.add_dependency "kaminari"
  s.add_dependency "turbolinks"
  s.add_dependency "bootstrap-kaminari-views"
  s.add_dependency "bh"
  s.add_dependency "rails-i18n"
  s.add_dependency "cancancan"
  s.add_dependency "awesome_print"
  s.add_dependency "kaminari-i18n"
  s.add_dependency "bootstrap-datepicker-rails"
  s.add_dependency "carrierwave"
  s.add_dependency "aasm"
  s.add_dependency "handles_sortable_columns"
  s.add_dependency "pdf-reader"
  s.add_dependency "prawn"
  s.add_dependency "prawn-table"
  s.add_dependency "combine_pdf"
  s.add_dependency "cocoon"
  s.add_dependency "selectize-rails"
  s.add_dependency "acts-as-taggable-on"
  s.add_dependency "mini_magick"
  s.add_dependency "rake"
  s.add_dependency "axlsx"
  s.add_dependency "zip-zip"
end
