module Reptile
  # The Users class is holds the different sets of parameters for logging into a database, 
  # including username, password, etc. There are read_only configs, replication user configs, 
  # heartbeat configs, etc, for correctly and safely allowing access to different databases for
  # different reasons.  
  #
  # This also data also is used to create the permissions, allowing the setup of replication 
  # to be even easier.
  class Users
    def initialize(options)
      return if options.nil?
      
      @repl_user = options["replication_user"]
      @ro_user = options["ro_user"]
      @heartbeat_user = options["heartbeat_user"]
    end
    
    
    def self.prompt_for_grant_user
      require 'rubygems'
      require 'highline'
      
      asker = HighLine.new
      asker.say("Please enter credentials for a user that has GRANT priviledges.")
      {:username => asker.ask("Enter your username:"), 
       :password => asker.ask("Enter your password:  ") { |q| q.echo = "x" }}
    end
    
    # # Set the user settings for a user that has REPLICATION SLAVE privilidgess
    # def replication_user=(replication_user_settings)
    #   @repl_user = replication_user_settings
    # end

    # The user settings for a user that has REPLICATION SLAVE privilidgess
    def replication_user
      # TODO: only bail on getting a user if it is acutally used
      #raise "You need to specify a replication user!" if @repl_user.nil?
      @repl_user
    end
        
    
    # # Set the user settings for a user that has SELECT privilidgess
    # def ro_user=(ro_user_settings)
    #   @ro_user = ro_user_settings
    # end

    # The user settings for a user that has SELECT privilidgess
    def ro_user
      #raise "You need to specify a SELECT user!" if @ro_user.nil?
      @ro_user || {}
    end
    

    # # Set the user settings for a user that has reads/writes heartbeats
    # def heartbeat_user=(heartbeat_user_settings)
    #   @heartbeat_user = heartbeat_user_settings
    # end

    # The user settings for a user that reads/writes heartbeats
    def heartbeat_user
      #raise "You need to specify a heartbeat user!" if @heartbeat_user.nil?
      @heartbeat_user || {}
    end

  end
end