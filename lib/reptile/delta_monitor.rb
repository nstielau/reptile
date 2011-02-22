module Reptile
  # This monitor compares the row counts for each table for each master and slave.
  class DeltaMonitor
    # Set the user settings for a user that has global SELECT privilidgess
    def self.user=(user_settings)
      @user = user_settings
    end

    # The user settings for a user that has global select privilidgess
    def self.user
      raise "You need to specify a user!" if @user.nil?
      @user
    end

    # Retrieve the active database connection.  Nil of none exists.
    def self.connection
      ActiveRecord::Base.connection
    end

    # Compares the row counts for master tables and slave tables
    # Returns a hash of TABLE_NAME => ROW COUNT DELTAs
    def self.diff(db_name, master_configs, slave_configs)
      ActiveRecord::Base.establish_connection(slave_configs.merge(user))
      slave_counts = get_table_counts

      ActiveRecord::Base.establish_connection(master_configs.merge(user))
      master_counts = get_table_counts

      deltas= {}
      master_counts.each do |table, master_count|
        if slave_counts[table].nil?
          Log.error "Table '#{table}' exists on master but not on slave."
          next
        end
        delta = master_count.first.to_i - slave_counts[table].first.to_i
        deltas[table] = delta
      end

      print_deltas(db_name, deltas, master_configs)

      deltas
    rescue Exception => e
      Log.error "Error: Caught #{e}"
      Log.error "DB Name: #{db_name}"
      Log.error "Master Configs: #{master_configs.inspect}"
      Log.error "Slave Configs: #{slave_configs.inspect}"
      raise e
    end

    # Prints stats about the differences in number of rows between the master and slave
    def self.print_deltas(db_name, deltas, configs)
      non_zero_deltas = deltas.select{|table, delta| not delta.zero?}
      if non_zero_deltas.size.zero?
        Log.info "Replication counts A-OK for #{db_name} on #{configs['host']} @ #{Time.now}"
      else
        Log.info "Replication Row Count Deltas for #{db_name} on #{configs['host']} @ #{Time.now}"
        Log.info "There #{non_zero_deltas.size > 1 ? 'are' : 'is'} #{non_zero_deltas.size} #{non_zero_deltas.size > 1 ? 'deltas' : 'delta'}"
        non_zero_deltas.each do |table, delta|
          Log.info "  #{table} table: #{delta}" unless delta.zero?
        end
      end
    end

    # Returns an array of strings containing the table names
    # for the current database.
    def self.get_tables
      tables = []
      connection.execute('SHOW TABLES').each { |row| tables << row }
      tables
    end

    # Returns a hash of TABLE_NAME => # Rows for all tables in current db
    def self.get_table_counts
      tables = get_tables

      tables_w_count = {}
      tables.each do |table|
        connection.execute("SELECT COUNT(*) FROM #{table}").each do |table_count|
          tables_w_count["#{table}"] = table_count
        end
      end
      tables_w_count
    end
  end
end