# -*- encoding: utf-8 -*-
require File.expand_path("../lib/reptile/version", __FILE__)

Gem::Specification.new do |s|
  s.name = "reptile"
  s.version = Reptile::VERSION
  s.platform = Gem::Platform::RUBY

  s.authors = ["nick.stielau@gmail.com"]
  s.date = "2010-01-05"
  s.default_executable = "replication_status"
  s.description = "Cold blooded mysql replication monitoring."
  s.email = "nick.stielau@gmail.com"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'

  s.homepage = %q{http://reptile.rubyforge.org/}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.required_rubygems_version = ">= 1.3.6"

  s.summary = "Cold blooded mysql replication monitoring."

  s.add_development_dependency "bundler", ">= 1.0.0"

  s.add_runtime_dependency "tlsmail", ">= 0.0.1"
  s.add_runtime_dependency "activerecord", ">= 0"
  s.add_runtime_dependency "mixlib-log", ">= 1.2.0"
end

