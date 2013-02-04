namespace RedshiftScheduler {

	void main(string[] args) {
		ApplicationConfig config;
		try {
			config = new ApplicationConfig.from_args(ref args);
		} catch (ApplicationConfigError e) {
			stderr.printf("%s\n", e.message);
			return;
		}

		if (config.show_version) {
			stdout.printf("redshift-scheduler %s\n", Application.VERSION);
			return;
		}

		File rules_file = File.new_for_path(config.rules_path);
		IRulesProvider rules_provider = new LiveFileRulesProvider(new FileRulesProvider(rules_file));
		ITemperatureDeterminer temperature_determiner = new RulesBasedTemperatureDeterminer(rules_provider);

		Application app = new Application(config, temperature_determiner, new RedshiftTemperatureSetter());
		app.set_power_resume_detector(new DBusPowerResumeDetector());
		app.set_logger(new StandardLogger(config.debug_mode));
		app.run();

		new MainLoop().run();
	}

}
