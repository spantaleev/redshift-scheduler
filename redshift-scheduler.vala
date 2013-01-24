namespace RedshiftScheduler {

	class Application {

		private ITemperatureDeterminer temperature_determiner;
		private ITemperatureSetter temperature_setter;
		private IPowerResumeDetector? power_resume_detector;
		private ILogger logger;
		private int? last_temperature_set;

		public Application(ITemperatureDeterminer temperature_determiner, ITemperatureSetter temperature_setter, ILogger logger) {
			this.temperature_determiner = temperature_determiner;
			this.temperature_setter = temperature_setter;
			this.logger = logger;
		}

		public void set_power_resume_detector(IPowerResumeDetector detector) {
			this.power_resume_detector = detector;
		}

		public int run() {
			this.logger.install();

			this.change_temperature();

			Timeout.add(60000, () => {
				this.change_temperature();
				return true;
			});

			if (this.power_resume_detector != null) {
				this.power_resume_detector.resuming.connect(() => {
					debug("Activating after a system power resume");
					this.change_temperature();
				});
			}

			return 0;
		}

		public void change_temperature() {
			try {
				int temperature = this.temperature_determiner.determine_temperature();

				if (this.last_temperature_set != temperature) {
					message("Temperature determined to be: %dK", temperature);
					this.temperature_setter.set_temperature(temperature);
					this.last_temperature_set = temperature;
					message("Temperature set to: %dK", temperature);
				} else {
					message("Temperature remains the same as last time (%dK) - not doing anything", temperature);
				}
			} catch (TemperatureDeterminerError e) {
				stderr.printf(e.message);
			} catch (TemperatureSetterError e) {
				stderr.printf(e.message);
			}
		}

	}

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

		ILogger logger = new StandardLogger(debug);

		Application app = new Application(temperature_determiner, new RedshiftTemperatureSetter(), logger);
		app.set_power_resume_detector(new DBusPowerResumeDetector());
		app.run();

		new MainLoop().run();
	}

}
