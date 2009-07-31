require 'active_record'

module Reptile
  # MySQL DTD for setting up Heartbeats.  Change HEARTBEAT_USER, HEARTBEAT_PASS, and MONITORING_BOX 
  # to ip of the monitoring server. 
  #
  # GRANT SELECT, INSERT, UPDATE, ALTER ON replication_monitor.* 
  # TO 'HEARTBEAT_USER'@"localhost" IDENTIFIED BY 'HEARTBEAT_PASS';  GRANT SELECT, INSERT, UPDATE,
  # ALTER ON replication_monitor.* TO 'HEARTBEAT_USER'@"MONITORING_BOX" IDENTIFIED BY 'HEARTBEAT_PASS';
  # 
  # CREATE DATABASE replication_monitor;
  # 
  # CREATE TABLE replication_monitor.heartbeats (
  #   unix_time INTEGER NOT NULL, 
  #   db_time TIMESTAMP NOT NULL, 
  #   INDEX time_idx(unix_time)
  # )
  #
  class Heartbeat < ActiveRecord::Base

    # Set the default connection settings for writing/reading heartbeats.
    # These will be merged with the per-database settings passed to <code>connect</code>.
    def self.user=(default_configs)
      @user = default_configs
    end
  
    # The default connection settings which override per-database settings.
    def self.user
      @user ||= {}
    end
  
    # Merge the connection settings in the configs parameter with HeartBeat defaults. 
    def self.connect(configs)
      ReplicationMonitor.connect(configs.merge(user))
    end
  
    # Write a heartbeat.
    # Thump thump.
    def self.write(name, configs)
      connect(configs)
      heartbeat = Heartbeat.create(:unix_time => Time.now.to_i, :db_time => "NOW()")
      log "Wrote heartbeat to #{name} at #{Time.at(heartbeat.unix_time)}"
    end

    # Read the most recent heartbeat and return the delay in seconds, or nil if no heartbeat are found.
    def self.read(name, configs)
      connect(configs)
    
      current_time = Time.now

      delay = nil
      heartbeat = Heartbeat.find(:first, :order => 'db_time DESC')
    
       # No heartbeats at all!
      if heartbeat.nil?
        log "No heartbeats found on #{name} at #{Time.now}"
        return nil;
      end
   
      # Not sure why we have both, (one is easier to read?).
      # Use one or the other to calculate delay...
      delay = (Time.now - Time.at(heartbeat.unix_time)).round
      #delay = (Time.now - heartbeat.db_time)

      log "Read heartbeat from #{name} at #{Time.at(heartbeat.unix_time)}. The delay is #{strfdelay(delay)}"
    
      delay
    end
   
private
   
    # Open the 'heartbeat.log' file.
    def self.open_log
      logFile = 'heartbeat.log'
      @logFileObj = File.open(logFile, "a")
    end
  
    # Log a message, both to the file and standard out.
    def self.log(msg)
      open_log if @logFileObj.nil?
      puts msg
      @logFileObj.puts msg
    end
    
    # Format the delay (in seconds) as a human-readable string.
    def self.strfdelay(delay)
      seconds = delay % 60
      minutes = delay / 60 % 60
      hours = delay / 60 / 60
      delay_str = ""
      delay_str << "#{hours} hours" if hours > 0
      delay_str << " " if !hours.zero? && (minutes > 0 || seconds > 0)
      delay_str << "#{minutes} minutes" if minutes > 0
      delay_str << " " if (!minutes.zero? || !hours.zero?) && seconds > 0
      delay_str << "#{seconds} seconds" unless seconds.zero?
      delay_str
    end
  end
end