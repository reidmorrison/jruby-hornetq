raise "jruby-hornetq must be built with JRuby: try again with `jruby -S rake'" unless defined?(JRUBY_VERSION)

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'rake/clean'
require 'rake/testtask'
require 'date'
require 'java'
require 'hornetq/version'

desc "Build gem"
task :gem  do |t|
  gemspec = Gem::Specification.new do |s|
    s.name        = 'jruby-hornetq'
    s.version     = HornetQ::VERSION
    s.authors     = ['Reid Morrison', 'Brad Pardee']
    s.email       = ['reidmo@gmail.com', 'bpardee@gmail.com']
    s.homepage    = 'https://github.com/ClarityServices/jruby-hornetq'
    s.date        = Date.today.to_s
    s.description = 'JRuby-HornetQ is a Java and Ruby library that exposes the HornetQ Java API in a ruby friendly way. For JRuby only.'
    s.summary     = 'JRuby interface into HornetQ'
    s.files       = FileList["./**/*"].exclude(/.gem$/, /.log$/,/^nbproject/).map{|f| f.sub(/^\.\//, '')}
    s.license     = "Apache License V2.0"
    s.has_rdoc    = true
    s.executables = %w(hornetq_server)
    s.add_dependency "gene_pool", "~> 1.1.1"
  end
  Gem::Builder.new(gemspec).build
end

desc "Run Test Suite"
task :test do
  Rake::TestTask.new(:functional) do |t|
    t.test_files = FileList['test/*_test.rb']
    t.verbose    = true
  end

  Rake::Task['functional'].invoke
end
