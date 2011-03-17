module Reptile
  class ReplicationMonitor

    # Attempts to load the replication.yml configuration file.
    def self.load_config_file(databases_file)
      @databases_file = databases_file
      yaml = YAML::load(File.read(@databases_file))
      @configs = yaml.delete('config')
      @users = Users.new(yaml.delete('users'))
      @databases = Databases.new(yaml)

      Heartbeat.user = users.heartbeat_user
      Runner.user = users.replication_user
      Status.user = users.replication_user
      DeltaMonitor.user = users.ro_user
      Runner.databases = databases

      raise "Please specify a delay threshold 'delay_threshold_secs: 360'" if @configs['delay_threshold_secs'].nil?
      raise "Please specify a row delta threshold 'row_difference_threshold: 10'" if @configs['row_difference_threshold'].nil?
    rescue Errno::EACCES => e
      Log.error "Unable to open config file: Permission Denied"
    end

    # Returns the configs from the replication.yml file
    def self.configs
      @configs
    end

    # Returns the databases from the yml file.
    def self.databases
      @databases
    end

    # Returns the +Users+ loaded from the replication.yml file
    def self.users
      @users
    end

    def self.diff_tables
      Log.info "Checking row counts."
      unsynced_dbs = 0

      databases.databases.each_pair do |name, roles|
        master, slave = roles['master'], roles['slave']
        deltas = DeltaMonitor.diff(name, master, slave)

        egregious_deltas = deltas.select{|table, delta| delta > configs['row_difference_threshold'] }
        if egregious_deltas.size > 0
          log_replication_error :host => master["host"], :database => master["database"], :deltas => egregious_deltas, :noticed_at => Time.now
          unsynced_dbs += 1
        end
      end

      unsynced_dbs.zero?
    end

    def self.heartbeat
      Log.info "Checking heartbeats."
      databases.masters.each_pair do |name, configs|
        Heartbeat.write(name, configs)
      end

      overdue_slaves = 0

      databases.slaves.each_pair do |name, db_configs|
        delay = Heartbeat.read(name, db_configs)
        if delay.nil?
          log_replication_error :host => name,
                                    :database => configs[:database],
                                    :general_error => "Error: No Heartbeats found.",
                                    :noticed_at => Time.now
          overdue_slaves += 1
        elsif delay > configs['delay_threshold_secs']
          log_replication_error :host => name,
                                    :database => configs[:database],
                                    :delay => Heartbeat.strfdelay(delay),
                                    :noticed_at => Time.now
          overdue_slaves += 1
        end
      end

      overdue_slaves.zero?
    end

    # Checks the status of each slave.
    def self.check_slaves
      Log.info "Checking slave status."
      databases.slaves.each do |slave_name, slave_configs|
        status = Status.check_slave_status(slave_name, slave_configs)
        Log.info "'#{slave_name}' is '#{status}'"
        if status != Status.const_get(:RUNNING)
          log_replication_error :host => slave_name,
                                    :database => configs[:database],
                                    :status_error => Status.get_error_message(status),
                                    :noticed_at => Time.now
        end
      end
    end

    def self.log_replication_error(options)
      Log.error "A replication error occured on #{options[:host]} at #{Time.now}"

      if options[:delay]
        Log.error "There was a #{options[:delay]} second replication latency, which is greater than the allowed latency of #{configs['delay_threshold_secs']} seconds"
      elsif options[:deltas]
        Log.error "The following tables have master/slave row count difference greater than the allowed #{configs['row_difference_threshold']}"
        options[:deltas].each do |table, delta|
          Log.error "   table '#{table}' was off by #{delta} rows"
        end
      elsif options[:status_error]
          Log.error "   MySQL Status message: #{options[:status_error]}"
      elsif options[:general_error]
          Log.error "   Error: #{options[:general_error]}"
      end

      Log.error "  Server: #{options[:host]}\n"
      Log.error "  Database: #{options[:database]}\n" unless options[:database].blank?
    end

    def self.report
      Log.info "Generating report"

      old_stdout = $stdout
      out = StringIO.new
      $stdout = out
      begin
        puts "Daily Replication Report for #{Time.now.strftime('%D')}"
        puts "                       Checking slave status"
        puts
        self.check_slaves
        puts
        puts
        puts "                       Checking table row counts"
        puts
        puts "The row count difference threshold is #{configs['row_difference_threshold']} rows"
        puts
        self.diff_tables
        puts
        puts
        puts "                       Checking replication heartbeat"
        puts
        puts "The heartbeat latency threshold is #{configs['delay_threshold_secs']} seconds"
        puts
        self.heartbeat
      ensure
         $stdout = old_stdout
      end
      puts out.string
    end
  end
end