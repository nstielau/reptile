require 'rubygems' unless ENV['NO_RUBYGEMS']
%w[rake rake/clean fileutils newgem rubigen].each { |f| require f }
require File.dirname(__FILE__) + '/lib/reptile'

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.new('reptile', Reptile::VERSION) do |p|
  p.developer('Nick Stielau', 'nick.stielau@gmail.com')
  p.changes              = p.paragraphs_of("History.txt", 0..1).join("\n\n")
  p.post_install_message = 'PostInstall.txt'
  p.rubyforge_name       = p.name
  p.bin_files            = ["bin/replication_status"]
  p.extra_dev_deps = [
    ['newgem', ">= #{::Newgem::VERSION}"]
  ]
  
  p.clean_globs |= %w[**/.DS_Store tmp *.log]
  path = (p.rubyforge_name == p.name) ? p.rubyforge_name : "\#{p.rubyforge_name}/\#{p.name}"
  p.remote_rdoc_dir = File.join(path.gsub(/^#{p.rubyforge_name}\/?/,''), 'rdoc')
  p.rsync_args = '-av --delete --ignore-errors'
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
