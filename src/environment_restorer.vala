namespace RedshiftScheduler {

	/**
	 * Restores the temperature when the program exits.
	 *
	 * We need to use static methods/variables, because Posix
	 * signal handler functions are "without a target" and
	 * therefore cannot be used as a closure or refer to an instance member.
	 */
	class EnvironmentRestorer {

		private static ITemperatureSetter setter;

		public static void setup(ITemperatureSetter setter) {
			EnvironmentRestorer.setter = setter;

			int[] signals = {Posix.SIGHUP, Posix.SIGINT, Posix.SIGTERM};
			foreach (int signum in signals) {
				Posix.signal(signum, () => {
					EnvironmentRestorer.restore_temperature_and_exit();
				});
			}
		}

		private static void restore_temperature_and_exit() {
			try {
				EnvironmentRestorer.setter.set_temperature(TEMPERATURE_MAX);
			} catch (TemperatureSetterError e) {
				message("Cannot restore temperature: %s", e.message);
			}
			Process.exit(0);
		}

	}

}
