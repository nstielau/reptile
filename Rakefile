require 'rubygems' unless ENV['NO_RUBYGEMS']
%w[rake rake/clean fileutils newgem rubigen].each { |f| require f }
require File.dirname(__FILE__) + '/lib/reptile'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "reptile"
    gem.summary = %Q{Cold blooded mysql replication monitoring.}
    gem.description = %Q{Cold blooded mysql replication monitoring.}
    gem.email = "nick.stielau@gmail.com"
    gem.homepage = "http://reptile.rubyforge.org/"
    gem.authors = ["Nick Stielau"]
    gem.add_runtime_dependency 'tlsmail', '>= 0'
    gem.add_runtime_dependency 'active_record', '>= 0'
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

desc "Upload current documentation to Rubyforge"
task :upload_docs => [:redocs] do
  sh "scp -r doc/* nstielau@rubyforge.org:/var/www/gforge-projects/reptile/doc"
end

desc "Upload current documentation to Rubyforge"
task :upload_site do
  #webgen && scp -r output/* nstielau@rubyforge.org:/var/www/gforge-projects/reptile/
  sh "scp -r webgen_site/* nstielau@rubyforge.org:/var/www/gforge-projects/reptile/"
end

require 'newgem/tasks' # load /tasks/*.rake
Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# task :default => [:spec, :features]
