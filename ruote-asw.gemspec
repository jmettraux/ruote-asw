
Gem::Specification.new do |s|

  s.name = 'ruote-asw'

  s.version = File.read(
    File.expand_path('../lib/ruote/asw/version.rb', __FILE__)
  ).match(/VERSION *= *['"]([^'"]+)/)[1]

  s.platform = Gem::Platform::RUBY
  s.authors = [ 'John Mettraux' ]
  s.email = [ 'jmettraux@gmail.com' ]
  s.homepage = 'http://ruote.rubyforge.org'
  s.rubyforge_project = 'ruote'
  s.summary = 'Amazon Simple Workflow (SWF) storage for ruote'
  s.description = %q{
Amazon Simple Workflow (SWF) storage for ruote (a workflow engine)
  }.strip

  #s.files = `git ls-files`.split("\n")
  s.files = Dir[
    'Rakefile',
    'lib/**/*.rb', 'spec/**/*.rb', 'test/**/*.rb',
    '*.gemspec', '*.txt', '*.md'
  ]

  s.add_runtime_dependency 'ruote', ">= #{s.version.to_s.split('.')[0, 3].join('.')}"
  s.add_runtime_dependency 'net-http-persistent', '>= 2.8'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '>= 2.12'

  s.require_path = 'lib'
end

