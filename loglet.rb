require 'yaml'

module Loglet

	class Log

		@config_file_path = nil
		@log_file_base_path = nil
		@config = nil
		@module_base_path = nil

		def initialize(config_file = nil, absolute = false)
			config_file = 'config.yml' if config_file.nil?

			#get config dir path
			@module_base_path = File.expand_path(__FILE__).gsub('loglet.rb', '')

			if absolute && !config_file.nil?
				@config_file_path = conf_file
			else
				@config_file_path = File.join(@module_base_path, config_file)
			end
			
			#check if config file exists and load it in
			if File.exists?(@config_file_path)
				@config = YAML.load_file(@config_file_path)
			else
				puts "Missing config file: #{@config_file_path}"
			end

			#check whether we should write to basic path or not (root of module path for logs)
			if @config['path'].nil?
				@log_file_base_path = File.join(@module_base_path, 'logs')
			else
				@log_file_base_path = @config['log_path']
			end

			#check if log path is writable
			puts "Current log path directory is not writable: #{@config['log_path']}" unless log_path_writable?
		end

		#open a log file
		def open(f)
			File.open("#{File.join(@log_file_base_path, f)}", 'r') if File.exists?("#{File.join(@log_file_base_path, f)}")
		end

		#current logs
		def current_logs()
			files = Dir.entries(@log_file_base_path).collect {|file| file if file != '.' && file != '..'}.compact!
		end

		#write to log file
		def write(text, type = 'access')
			create_log_base_path_folder
			file = File.join(@log_file_base_path, write_to(type))

			operation = "w"
			operation = "a" if File.exists?(file)
			File.open(file, operation) { |f| f.puts "[#{Time.now}] #{text}" }
		end

		private

		#test if log base path exists if not we create the directory
		def create_log_base_path_folder
			Dir.mkdir(@log_file_base_path) if ! File.directory?(@log_file_base_path)
		end

		#figure out what file to write to
		def write_to(type = 'access')
			file_name = ''

			#base it on the type
			case type.downcase
				when 'error'
					file_name += @config['error_file_name']
				when 'debug'
					file_name += @config['debug_file_name']
				when 'access'
					file_name += @config['access_file_name']
			end
			
			#check for daily logging
			file_name += "-#{daily_file_name}" if @config['daily']
			file_name += ".log"
		end

		#figure out todays date
		def daily_file_name
			time = Time.new
			"#{time.month}-#{time.day}-#{time.year}"
		end

		#check if log path is writable
		def log_path_writable?
			FileTest.writable?( @config['log_path'] )
		end
	end

end