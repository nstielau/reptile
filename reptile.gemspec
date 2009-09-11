# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{reptile}
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nick Stielau"]
  s.date = %q{2009-08-13}
  s.default_executable = %q{replication_status}
  s.description = %q{}
  s.email = ["nick.stielau@gmail.com"]
  s.executables = ["replication_status"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc"]
  s.files = ["History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc", "Rakefile", "bin/replication_status", "lib/reptile.rb", "lib/reptile/databases.rb", "lib/reptile/delta_monitor.rb", "lib/reptile/dtd.sql", "lib/reptile/heartbeat.rb", "lib/reptile/replication_monitor.rb", "lib/reptile/runner.rb", "lib/reptile/status.rb", "lib/reptile/users.rb", "script/console", "script/destroy", "script/generate", "test/test_helper.rb", "test/test_reptile.rb"]
  s.has_rdoc = true
  s.homepage = %q{Reptile is an easy to use utility that will monitor your MySQL replication, so you can forget about it and focus on the good stuff.  It provides a utility for generate replication reports, and can email if replication appears to be failing.}
  s.post_install_message = %q{PostInstall.txt}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{reptile}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Cold-blooded MySQL replication monitoring.}
  s.test_files = ["test/test_helper.rb", "test/test_reptile.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<newgem>, [">= 1.4.1"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<newgem>, [">= 1.4.1"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<newgem>, [">= 1.4.1"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end
