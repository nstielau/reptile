$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'ostruct'
require 'openssl'
require 'rubygems'
require 'tlsmail'
require 'net/smtp'

require 'reptile/heartbeat'
require 'reptile/delta_monitor'
require 'reptile/replication_monitor'
require 'reptile/status'
require 'reptile/runner'
require 'reptile/users'
require 'reptile/databases'