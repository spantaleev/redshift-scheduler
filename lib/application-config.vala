namespace RedshiftScheduler {

	public errordomain ApplicationConfigError {
		GENERIC_FAILURE
	}

	class ApplicationConfig {

		public const string version = "dev";

		public string rules_path;
		public int temperature_change_interval;
		public bool debug_mode;
		public bool show_version;

		public ApplicationConfig.from_args(ref unowned string[] args) throws ApplicationConfigError {
			try {
				OptionsParser.parse(this, ref args);
			} catch (OptionError e) {
				throw new ApplicationConfigError.GENERIC_FAILURE(e.message);
			}

			if (this.rules_path == null && !this.show_version) {
				throw new ApplicationConfigError.GENERIC_FAILURE("A rules file needs to be specified.");
			}

			if (this.temperature_change_interval < 1) {
				throw new ApplicationConfigError.GENERIC_FAILURE("The temperature change interval cannot be less than 1.");
			}
		}

	}

	private class OptionsParser {

		private static string rules_path;
		private static int temperature_change_interval = 1;
		private static bool debug_mode;
		private static bool show_version;

		const OptionEntry[] options = {
			{ "rules-path", 'r', 0, OptionArg.FILENAME, ref rules_path, "Path to rules file", null },
			{ "temperature-change-interval", 'i', 0, OptionArg.INT64, ref temperature_change_interval, "How often and gradually to change the temperature (minutes)", "1" },
			{ "debug", 'd', 0, OptionArg.NONE, ref debug_mode, "Enable debug mode", null },
			{ "version", 'v', 0, OptionArg.NONE, ref show_version, "Show version number", null },
			{ null }
		};

		public static void parse(ApplicationConfig config, ref unowned string[] args) throws OptionError {
			OptionContext opt_context = new OptionContext("- schedule redshift");
			opt_context.set_help_enabled (true);
			opt_context.add_main_entries(OptionsParser.options, null);

			opt_context.parse(ref args);

			config.rules_path = OptionsParser.rules_path;
			config.temperature_change_interval = OptionsParser.temperature_change_interval;
			config.debug_mode = OptionsParser.debug_mode;
			config.show_version = OptionsParser.show_version;
		}

	}

}
