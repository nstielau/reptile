require 'tlsmail'

module Reptile
  # The Status class is responsible for asking a slave database for its status is, 
  # parsing the result, and returning the appropiate status code.
  #
  # This class also allows you to convert a status code to a friendly message the corresponds to that status.
  
  class Status

    @@errors = []
    
    # Status code indicating the SQL thread has stopped running.
    SQL_THREAD_DOWN = 'sql_thread_down'
    
    # Status code indicating the IO thread has stopped running.
    IO_THREAD_DOWN = 'io_thread_down'
    
    # Status code indicating that the slave has stopped replicating.
    SLAVE_DOWN = 'slave_down'
    
    # Status code indicating that the slave is up and running.
    RUNNING = 'running'
    
    # Set the user settings for a user that has global SELECT privilidgess
    def self.user=(user_settings)
      @user = user_settings
    end

    # The user settings for a user that has global select privilidgess
    def self.user
      @user ||= {}
    end
    
    # Checks the value of the MySQL command "SHOW SLAVE STATUS".
    # Returns a status code.
    def self.check_slave_status(name, configs)
      # TODO: Do this in Databases
      configs.delete("port")
      Databases.connect(configs.merge(user).merge('database' => 'information_schema')).execute('SHOW SLAVE STATUS').each_hash do |hash|
        
        if hash['Slave_SQL_Running'] == "No"
          return SQL_THREAD_DOWN
        elsif hash['Slave_IO_Running'] == "No"
          return IO_THREAD_DOWN
        elsif hash['Slave_Running'] == "No"
          return SLAVE_DOWN
        else
          return RUNNING
        end
      end
    end 
    
    # Returns a nice error message for the given status code
    def self.get_error_message(status)
      case status
      when SQL_THREAD_DOWN
        "The SQL thread has stopped"
      when IO_THREAD_DOWN
        "The IO thread has stopped"
      when SLAVE_DOWN
        "The slave has stoppped"
      else
        raise "Invalid status code.  Must be one of #{status_codes.keys.inspect}"
      end
    end
    
    # A hash containing the names of the constants that represent status codes,
    # and the strings they represent
    def self.status_codes
      status_codes = {}
      self.constants.each do |const|
        status_codes[const] = const_get(const)
      end
      status_codes
    end
  end
end