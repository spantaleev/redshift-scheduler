namespace RedshiftScheduler {

	class Application {

		private ITemperatureDeterminer temperature_determiner;
		private ITemperatureSetter temperature_setter;
		private ILogger logger;

		public Application(ITemperatureDeterminer temperature_determiner, ITemperatureSetter temperature_setter, ILogger logger) {
			this.temperature_determiner = temperature_determiner;
			this.temperature_setter = temperature_setter;
			this.logger = logger;
		}

		public int run() {
			this.logger.install();

			this.change_temperature();

			Timeout.add(60000, () => {
				this.change_temperature();
				return true;
			});

			return 0;
		}

		public void change_temperature() {
			try {
				int temperature = this.temperature_determiner.determine_temperature();

				message("Temperature determined to be: %d", temperature);

				this.temperature_setter.set_temperature(temperature);

				message("Temperature set to: %d", temperature);
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
		app.run();

		new MainLoop().run();
	}

}
