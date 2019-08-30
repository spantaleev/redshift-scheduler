namespace RedshiftScheduler {

	public errordomain ApplicationConfigError {
		GENERIC_FAILURE
	}

	class ApplicationConfig {

		public string rules_path;
		public int temperature_change_interval = 1;
		public bool debug_mode;
		public bool print_mode;
		public bool show_version;

		public ApplicationConfig.from_args(ref unowned string[] args) throws ApplicationConfigError {
			try {
				this.parseArgs(ref args);
			} catch (OptionError e) {
				throw new ApplicationConfigError.GENERIC_FAILURE(e.message);
			}

			if (this.rules_path == null) {
				this.rules_path = GLib.Environment.get_user_config_dir() + "/redshift-scheduler/rules.conf";
			}

			if (this.temperature_change_interval < 1) {
				throw new ApplicationConfigError.GENERIC_FAILURE("The temperature change interval cannot be less than 1.");
			}
		}

		private void parseArgs(ref unowned string[] args) throws OptionError {
			OptionEntry[] options = {
				OptionEntry() {
					long_name = "rules-path", short_name = 'r', flags = 0, arg = OptionArg.FILENAME,
					arg_data = &this.rules_path,
					description = "Path to rules file", arg_description = "$XDG_CONFIG_HOME/redshift-scheduler/rules.conf"
				},
				OptionEntry() {
					long_name = "temperature-change-interval", short_name = 'i', flags = 0, arg = OptionArg.INT,
					arg_data = &this.temperature_change_interval,
					description = "How often and gradually to change the temperature (minutes)", arg_description = "1"
				},
				OptionEntry() {
					long_name = "debug", short_name = 'd', flags = 0, arg = OptionArg.NONE,
					arg_data = &this.debug_mode,
					description = "Enable debug mode", arg_description = null
				},
				OptionEntry() {
					long_name = "print", short_name = 'p', flags = 0, arg = OptionArg.NONE,
					arg_data = &this.print_mode,
					description = "Print temperature that would be in effect now according to current rules", arg_description = null
				},
				OptionEntry() {
					long_name = "version", short_name = 'v', flags = 0, arg = OptionArg.NONE,
					arg_data = &this.show_version,
					description = "Show version number", arg_description = null
				}
			};

			OptionContext opt_context = new OptionContext("- schedule redshift");
			opt_context.set_help_enabled(true);
			opt_context.add_main_entries(options, null);
			opt_context.parse(ref args);
		}

	}

}
