require_relative 'lib/flyyer/version'

Gem::Specification.new do |spec|
  spec.name          = 'flyyer'
  spec.version       = Flyyer::VERSION
  spec.authors       = ['Patricio López Juri', 'Franco Méndez Z']
  spec.email         = ['patricio@flyyer.io', 'franco@flyyer.io']

  spec.summary       = 'FLYYER.io helper classes and methods'
  # spec.summary       = %q{TODO: Write a short summary, because RubyGems requires one.}
  spec.description   = 'FLYYER.io helper classes and methods'
  # spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = 'https://github.com/useflyyer/flyyer-ruby'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  # spec.metadata['allowed_push_host'] = 'TODO: Set to 'http://mygemserver.com''

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/useflyyer/flyyer-ruby'
  spec.metadata['changelog_uri'] = 'https://github.com/useflyyer/flyyer-ruby'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
