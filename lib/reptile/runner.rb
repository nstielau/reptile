module Reptile
  # The runner class is responsible for running command on each slave.  
  # The commands are run sequentially, no guaranteed order (though probably from yml file).
  class Runner
    # Set the user settings for a user that has REPLICATION SLAVE privilidgess
    def self.user=(replication_user_settings)
      @repl_user = replication_user_settings
    end

    # The user settings for a user that has REPLICATION SLAVE privilidgess
    def self.user
      raise "You need to specify a replication user!" if @repl_user.nil?
      @repl_user
    end

    # Set the databases to run command upon.
    def self.databases=(databases)
      @databases = databases
    end

    # The databases to run commands upon.
    def self.databases
      @databases
    end    

    # Set the slaves to run command upon.
    def self.slaves=(slaves)
      slaves.each do |name, configs|
        configs.delete('port')
        configs.delete('host')
        # With activeRecord, you have to connect to some DB, even if you are acting on the server...
        configs['database'] = 'information_schema' unless configs['database']
        # TODO: Delete these somewhere else
        configs.delete('heartbeat')
        configs.delete('replication_user')
      end
      @slaves = slaves
    end

    # The slaves to run commands upon.
    def self.slaves
      raise "You need to specify the slaves to run against!" if @slaves.nil?
      @slaves
    end
    
    
    # Tries to establish a database connection, and returns that connection.  
    # Dumps configs on error.
    def self.connect(configs)
      ActiveRecord::Base.establish_connection(configs)
      ActiveRecord::Base.connection
    rescue Exception => e
      puts "****"
      puts "Error connecting to database: #{e}"
      puts "****"
      puts YAML::dump(configs)
      exit 1
    end

    # Executes a command on all the slaves, sequentially.
    # Takes an optional set of connection paramters to override defaults.
    def self.execute_on_slaves(cmd, configs={})
      slaves.each do |name, slave_configs|
        puts "Executing #{cmd} on #{name}"
        puts slave_configs.inspect
        connection = connect(slave_configs.merge(user).merge(configs))
        connection.execute(cmd)
      end      
    end

    # Execute STOP SLAVE on all slaves;
    def self.stop_slaves
      execute_on_slaves("STOP SLAVE;")
    end
    
    # Execute START SLAVE on all slaves.
    def self.start_slaves
      execute_on_slaves("START SLAVE;")
    end 
    
    # Creates users with specific permissions on the different mysql servers, both masters and slaves.
    # Prompts for username and password of an account that has GRANT priviledges.
    def self.setup
      raise "GET CONFIGS"
      grant_user_configs = User.prompt_for_grant_user
      # TODO: use specific tables, not *.*
      # TODO: are these on localhost? or where?
      # TODO: We need all databases in order to grant permissions there.
      # TODO: There could be a different GRANT password for each mysql server, so identify which before asking for permissions.
      execute_on_slaves("GRANT select ON *.* TO #{ro_user}@???? INDENTIFIED BY #{ro_password}", grant_user_configs)
      execute_on_slaves("GRANT select ON *.* TO #{repl_user}@???? INDENTIFIED BY #{repl_password}", grant_user_configs)
    end
    
    def self.setup_heartbeat
      # MySQL DTD for setting up Heartbeats.  Change HEARTBEAT_USER, HEARTBEAT_PASS, and MONITORING_BOX to ip of the monitoring server.
      # GRANT SELECT, INSERT, UPDATE, ALTER ON replication_monitor.* TO 'HEARTBEAT_USER'@"localhost" IDENTIFIED BY 'HEARTBEAT_PASS';
      # GRANT SELECT, INSERT, UPDATE, ALTER ON replication_monitor.* TO 'HEARTBEAT_USER'@"MONITORING_BOX" IDENTIFIED BY 'HEARTBEAT_PASS';
      # 
      # CREATE DATABASE replication_monitor;
      # 
      # CREATE TABLE replication_monitor.heartbeats (
      #   unix_time INTEGER NOT NULL, 
      #   db_time TIMESTAMP NOT NULL, 
      #   INDEX time_idx(unix_time)
      # )
    end
    
    def self.test_connections
      databases.each do |db|
        databases.roles.each do |role|
          db[role]
        end
      end
    end
  end
end