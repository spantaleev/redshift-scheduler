namespace RedshiftScheduler {

	void main(string[] args) {
		if (args.length < 2) {
			stderr.printf("Usage: program <options> <path to definitions file>\n");
			return;
		}

		bool debug = "--debug" in args;
		string definitions_path = args[args.length - 1];

		File definitions_file = File.new_for_path(definitions_path);
		IRulesProvider rules_provider = new LiveFileRulesProvider(new FileRulesProvider(definitions_file));
		ITemperatureDeterminer temperature_determiner = new RulesBasedTemperatureDeterminer(rules_provider);

		Application app = new Application(temperature_determiner, new RedshiftTemperatureSetter());
		app.set_power_resume_detector(new DBusPowerResumeDetector());
		app.set_logger(new StandardLogger(debug));
		app.run();

		new MainLoop().run();
	}

}
