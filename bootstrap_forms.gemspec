$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "bootstrap_forms/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "bootstrap_forms"
  s.version     = BootstrapForms::VERSION
  s.authors     = ["Ondřej Ezr"]
  s.email       = ["ezrondre@fit.cvut.cz"]
  s.homepage    = "https://github.com/phoenixek12/bootstrap_forms"
  s.summary     = "BootstrapForms is a helper method which implement a rails form builder, which helps me to write forms the way I like it."
  s.description = "BootstrapForms has raised from a need in every bootstrap project I made, it is far from being nice coded gem, but it may help someone, so I share."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 3.2"

  s.add_development_dependency "sqlite3"
end
