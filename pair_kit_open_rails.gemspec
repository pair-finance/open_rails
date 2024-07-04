require File.expand_path('lib/pair_kit/open_rails/version', __dir__)

Gem::Specification.new do |spec|
  spec.name                  = 'pair-kit-open-rails'
  spec.version               = PairKit::OpenRails::VERSION
  spec.authors               = ['Dmitry Sharkov']
  spec.email                 = %w(dmitry.sharkov@gmail.com dmitry.sharkov@pairfinance.com)
  spec.summary               = 'Open Api on Rails'
  spec.description           = 'This is gems make Rails app compatible with Open API'
  spec.homepage              = 'https://github.com/pair-finance/open_rails'
  spec.license               = 'MIT'
  spec.platform              = Gem::Platform::RUBY
  spec.required_ruby_version = '>= 2.5.0'

  spec.metadata['homepage_uri']           = spec.homepage
  spec.metadata['source_code_uri']        = spec.homepage
  spec.metadata['changelog_uri']          = "#{spec.homepage}/blob/main/CHANGELOG.md"
  # spec.metadata['rubygems_mfa_required']  = 'true'

  spec.files = Dir['README.md', 'LICENSE',
                   'CHANGELOG.md', 'lib/**/*.rb',
                   'lib/**/*.rake',
                   'pair_kit_miniflector.gemspec', '.github/*.md',
                   'Gemfile', 'Rakefile']

  spec.extra_rdoc_files = ['README.md']

  spec.add_development_dependency 'pry-byebug', '~> 3.10', '>= 3.10.1'
  spec.add_development_dependency 'pry-alias', '~> 0.0', '>= 0.0.1'

  spec.add_development_dependency 'rubocop', '~> 1.64'
  spec.add_development_dependency 'rubocop-performance', '~> 1.20'
  spec.add_development_dependency 'rubocop-rspec', '~> 3.0'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.4'
  spec.add_development_dependency 'rspec-rails', '~> 3.4', '>= 3.4.2'

  spec.add_development_dependency 'simplecov', '~> 0.19'
  spec.add_development_dependency 'simplecov-cobertura', '~> 2.1'
end
