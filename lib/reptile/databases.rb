module Reptile
  # The Databases class stores information about different databases, including the config settings
  # for the master and slave of each particular database.
  class Databases
    attr :databases

    def initialize(databases)
      @databases = databases
    end

    # returns an array of the master names
    def masters
      @master_configs ||= get_masters
    end

    # returns an array of the slave names
    def slaves
      @slave_configs ||= get_slaves
    end

private

    def get_masters
      masters = databases.dup
      masters.each_key{|name| masters.delete(name) if masters[name]['master'].nil? }
      masters.each_key{|name| masters[name] = masters[name]['master'] }
      masters
    end

    # TODO: make private
    def get_slaves
      dbs = databases.dup
      dbs.each_key{|name| dbs.delete(name) if dbs[name]['slave'].nil? }
      dbs.each_key{|name| dbs[name] = dbs[name]['slave'] }
      slaves = dbs
    end

    # Tries to establish a database connection, and returns that connection.
    # Dumps configs on error
    def self.connect(configs)
      ActiveRecord::Base.establish_connection(configs)
      ActiveRecord::Base.connection
    rescue Exception => e
      Log.error "Error connecting to database: #{e}"
      Log.error configs.inspect
      exit 1
    end
  end
end