raise "jruby-hornetq must be built with JRuby: try again with `jruby -S rake'" unless defined?(JRUBY_VERSION)

require 'rake/clean'
require 'date'
require 'java'

desc "Build gem"
task :gem  do |t|
  gemspec = Gem::Specification.new do |s|
    s.name = 'jruby-hornetq'
    s.version = '0.2.4.alpha'
    s.authors = ['Reid Morrison', 'Brad Pardee']
    s.email = ['rubywmq@gmail.com', 'bpardee@gmail.com']
    s.homepage = 'https://github.com/ClarityServices/jruby-hornetq'
    s.date = Date.today.to_s
    s.description = 'JRuby-HornetQ is a Java and Ruby library that exposes the HornetQ Java API in a ruby friendly way. For JRuby only.'
    s.summary = 'JRuby interface into HornetQ'
    s.files = FileList["./**/*"].exclude('*.gem', './nbproject/*').map{|f| f.sub(/^\.\//, '')}
    s.has_rdoc = true
    s.add_dependency "gene_pool", "~> 1.1.1"
  end
  Gem::Builder.new(gemspec).build
end
