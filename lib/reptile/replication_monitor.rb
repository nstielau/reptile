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
      puts "Unable to open config file: Permission Denied"
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
      unsynced_dbs = 0

      databases.databases.each_pair do |name, roles|
        master, slave = roles['master'], roles['slave']
        deltas = DeltaMonitor.diff(name, master, slave)

        egregious_deltas = deltas.select{|table, delta| delta > configs['row_difference_threshold'] }
        if egregious_deltas.size > 0
          queue_replication_warning :host => master["host"], :database => master["database"], :deltas => egregious_deltas, :noticed_at => Time.now
          unsynced_dbs += 1
        end
      end

      unsynced_dbs.zero?
    end

    def self.heartbeat
      databases.masters.each_pair do |name, configs|
        Heartbeat.write(name, configs)
      end

      overdue_slaves = 0

      databases.slaves.each_pair do |name, db_configs|
        delay = Heartbeat.read(name, db_configs)
        if delay.nil?
          queue_replication_warning :host => name,
                                    :database => configs[:database],
                                    :general_error => "Error: No Heartbeats found.",
                                    :noticed_at => Time.now
          overdue_slaves += 1
        elsif delay > configs['delay_threshold_secs']
          queue_replication_warning :host => name,
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
      databases.slaves.each do |slave_name, slave_configs|
        status = Status.check_slave_status(slave_name, slave_configs)
        Log.info "'#{slave_name}' is '#{status}'"
        if status != Status.const_get(:RUNNING)
          queue_replication_warning :host => slave_name,
                                    :database => configs[:database],
                                    :status_error => Status.get_error_message(status),
                                    :noticed_at => Time.now
        end
      end
    end

    def self.queue_replication_warning(options)
      email = OpenStruct.new
      email.recipients = get_recipients
      email.subject = "A replication error occured on #{options[:host]} at #{Time.now}"
      email.body = ''

      if options[:delay]
        email.body +=  "There was a #{options[:delay]} second replication latency, which is greater than the allowed latency of #{configs['delay_threshold_secs']} seconds"
      elsif options[:deltas]
        email.body += "The following tables have master/slave row count difference greater than the allowed #{configs['row_difference_threshold']}\n\n"
        options[:deltas].each do |table, delta|
          email.body += "   table '#{table}' was off by #{delta} rows\n"
        end
      elsif options[:status_error]
          email.body += "   MySQL Status message: #{options[:status_error]}"
      elsif options[:general_error]
          email.body += "   Error: #{options[:general_error]}"
      end

      email.body += "\n"
      email.body += "  Server: #{options[:host]}\n"
      email.body += "  Database: #{options[:database]}\n" unless options[:database].blank?

      # Print out email body to STDOUT
      Log.error email.body

      send_email(email)
    end

    # Gets the 'email_to' value from the 'configs' section of the replication.yml file
    def self.get_recipients
      configs['email_to']
    end

    # Gets the 'email_from' value from the 'configs' section of the replication.yml file
    def self.get_sender
      configs['email_from']
    end

    def self.report
      email = OpenStruct.new
      email.recipients = get_recipients
      email.sender = get_sender
      raise "Please specify report recipients 'email_to: user@address.com'" if email.recipients.nil?
      raise "Please specify report recipients 'email_from: user@address.com'" if email.sender.nil?

      email.subject = "Daily Replication Report for #{Time.now.strftime('%D')}"

      puts "Generating report email"

      old_stdout = $stdout
      out = StringIO.new
      $stdout = out
      begin
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
      email.body = out.string

      puts "Sending report email"

      send_email(email)

      puts "Report sent to #{get_recipients}"
    end

    def self.send_exception_email(ex)
      email = OpenStruct.new
      email.recipients = get_recipients
      email.sender = get_sender
      email.subject = "An exception occured while checking replication at #{Time.now}"
      email.body = 'Expception\n\n'
      email.body += "#{ex.message}\n"
      ex.backtrace.each do |line|
         email.body += "#{line}\n"
      end

      send_email(email)
    end

    def self.send_email(email)
      return unless configs['email_server'] && configs['email_port'] && configs['email_domain'] &&
                    configs['email_password'] && configs['email_auth_type']

      # TODO: could do Net::SMTP.respond_to?(enable_tls) ? enable_TLS : puts "Install TLS gem to use SSL/TLS"
      Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
      Net::SMTP.start(configs['email_server'],
                        configs['email_port'],
                        configs['email_domain'],
                        get_sender,
                        configs['email_password'],
                        configs['email_auth_type'].to_sym) do |smtp|
          email.recipients.each do |email_addy|
            hdr = "From: #{email.sender}\n"
            hdr += "To: #{email_addy} <#{email_addy}>\n"
            hdr += "Subject: #{email.subject}\n\n"
            msg = hdr + email.body
            puts "Sending to #{email_addy}"
            smtp.send_message msg, email.sender,  email_addy
        end
      end
    # TODO: could try and recover
    # rescue Net::SMTPAuthenticationError => e
    #     if e.message =~ /504 5.7.4 Unrecognized authentication type/
    #       puts "Attempting to load necesary files for TLS/SSL authentication"
    #       puts "Make sure openssl and the tlsmail gem are installed"
    #       require 'openssl'
    #       require 'rubygems'
    #       has_tlsmail_gem = require 'tlsmail'
    #       raise "Please install the 'tlsmail' gem" unless has_tlsmail_gem
    #       Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
    #       send_email(email)
    #     end
    end
  end
end