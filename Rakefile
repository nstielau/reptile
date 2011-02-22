require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
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

task :test => :check_dependencies
task :default => :test
