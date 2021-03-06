
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "version"

Gem::Specification.new do |spec|
  spec.name          = "term-slides"
  spec.version       = Term::Slides::VERSION
  spec.authors       = ["yazgoo"]
  spec.email         = ["yazgoo@gmail.com"]

  spec.summary       = %q{run presentations in your terminal}
  spec.description   = %q{run presentations in your terminal}
  spec.homepage      = "https://github.com/yazgoo/term-slides"
  spec.license       = "MIT"


  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "colorize", "~> 0.8"
  spec.add_runtime_dependency "tty-table", "~> 0.10"
  spec.add_runtime_dependency "tty-command", "~> 0.8"
  spec.add_runtime_dependency "highline", "~> 2.0"
  spec.add_runtime_dependency "rouge", "~> 3.3"
  spec.add_runtime_dependency "os", "~> 1.0"
  spec.add_runtime_dependency "term-images", "~> 0.3"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
