namespace RedshiftScheduler {

	class Application {

		public const string VERSION = "dev";

		private ApplicationConfig config;
		private ITemperatureDeterminer temperature_determiner;
		private ITemperatureSetter temperature_setter;
		private IPowerResumeDetector? power_resume_detector;
		private int? last_temperature_set;

		public Application(ApplicationConfig config, ITemperatureDeterminer temperature_determiner, ITemperatureSetter temperature_setter) {
			this.config = config;
			this.temperature_determiner = temperature_determiner;
			this.temperature_setter = temperature_setter;
		}

		public void set_power_resume_detector(IPowerResumeDetector detector) {
			this.power_resume_detector = detector;
		}

		public int run() {
			this.change_temperature();

			this.temperature_determiner.temperature_outdated.connect(() => {
				debug("Activating, because of an outdated temperature value");
				this.change_temperature();
			});

			Timeout.add(this.config.temperature_change_interval * 60 * 1000, () => {
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

}
