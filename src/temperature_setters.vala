namespace RedshiftScheduler {

	public errordomain TemperatureSetterError {
		CANNOT_EXECUTE_DOMMAND
	}

	interface ITemperatureSetter : GLib.Object {
		public abstract void set_temperature(int temperature) throws TemperatureSetterError;
	}

	class RedshiftTemperatureSetter : GLib.Object, ITemperatureSetter {

		public void set_temperature(int temperature) throws TemperatureSetterError {
			//Redshift >= 1.12 requires a `-P` flag.
			//See https://github.com/jonls/redshift/issues/618
			string command = "redshift -P -O " + temperature.to_string() + "K";

			try {
				VersionInformation v = detect_redshift_version();
				if (v.major == 1 && v.minor < 12) {
					//Old versions do not support the `-P` flag, so we get rid of it.
					command = "redshift -O " + temperature.to_string() + "K";
				}
			} catch (VersionDetectionError e) {
				warning("Failed detecting redshift version. Temperature-setting command cannot be personalized: `%s`", e.message);
			}

			try {
				execute_command(command);
			} catch (CommandRunError e) {
				throw new TemperatureSetterError.CANNOT_EXECUTE_DOMMAND(e.message);
			}
		}

	}

}
