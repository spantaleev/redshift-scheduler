namespace RedshiftScheduler {

	int main(string[] args) {
		ApplicationConfig config;
		try {
			config = new ApplicationConfig.from_args(ref args);
		} catch (ApplicationConfigError e) {
			stderr.printf("%s\n", e.message);
			return 1;
		}

		ILogger logger = new StandardLogger(config.debug_mode);
		logger.install();

		if (config.show_version) {
			stdout.printf("redshift-scheduler %s\n", Application.VERSION);
			return 0;
		}

		File rules_file = File.new_for_path(config.rules_path);

		if (!rules_file.query_exists()) {
			if (!create_file_from_template(rules_file, "rules.conf.dist")) {
				critical("Could not create default rules file. The program is most likely installed incorrectly.");
				return 1;
			}

			message("Created a default rules file in `%s` - you can modify it to your liking now.", config.rules_path);
		}

		IRulesProvider rules_provider = new LiveFileRulesProvider(new FileRulesProvider(rules_file));
		ITemperatureDeterminer temperature_determiner = new RulesBasedTemperatureDeterminer(rules_provider);

		ITemperatureSetter temperature_setter = new RedshiftTemperatureSetter();

		EnvironmentRestorer.setup(temperature_setter);

		Application app = new Application(config, temperature_determiner, temperature_setter);
		app.set_power_resume_detector(new DBusPowerResumeDetector());
		app.run();

		new MainLoop().run();

		return 0;
	}

}
