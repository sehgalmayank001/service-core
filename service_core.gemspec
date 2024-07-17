# frozen_string_literal: true

require_relative "lib/service_core/version"

Gem::Specification.new do |spec|
  spec.name = "service_core"
  spec.version = ServiceCore::VERSION
  spec.authors = ["mayank sehgal"]
  spec.email = ["sehgalmayank001@gmail.com"]

  spec.summary       = "A Rails service pattern implementation"
  spec.description   = "A service pattern implementation for Rails applications, supporting validations and error handling."
  # spec.homepage = "TODO: Put your gem's website or public repo URL here."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  # spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activemodel", ">= 4.0", "< 7.0"
  spec.add_dependency "activesupport", ">= 4.0", "< 7.0"

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end


# service_core.gemspec

Gem::Specification.new do |spec|
  spec.name          = "service_core"
  spec.version       = ServiceCore::VERSION
  spec.authors       = ["Your Name"]
  spec.email         = ["your.email@example.com"]

  spec.summary       = "A Rails service pattern implementation"
  spec.description   = "A service pattern implementation for Rails applications, supporting validations and error handling."
  spec.homepage      = "https://your-gem-homepage.com"

  spec.files         = Dir["lib/**/*.rb"]
  spec.bindir        = "exe"
  spec.require_paths = ["lib"]

  spec.add_dependency "activemodel", ">= 4.0", "< 7.0"
  spec.add_dependency "activesupport", ">= 4.0", "< 7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://your-gem-source-code-repo.com"
  spec.metadata["changelog_uri"] = "https://your-gem-changelog.com"
end