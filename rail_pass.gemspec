$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rail_pass/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |gem|
  gem.name        = "rail_pass"
  gem.version     = RailPass::VERSION
  gem.authors     = ["Michael LaCroix", "James LaCroix"]
  gem.email       = ["info@lacroixdesign.net"]
  gem.summary     = "Rail Pass is a Ruby on Rails engine to configure new projects."
  gem.description = "Rail Pass is a Ruby on Rails engine to configure new projects with the default settings and templates used at LaCroix Design Co."
  gem.homepage    = "https://github.com/lacroixdesign/rail_pass"

  gem.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  gem.test_files = Dir["test/**/*"]

  gem.add_dependency "rails", "~> 3.2.11"
end
