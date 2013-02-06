namespace RedshiftScheduler {

	public errordomain TemperatureSetterError {
		CANNOT_EXECUTE_DOMMAND
	}

	interface ITemperatureSetter : GLib.Object {
		public abstract void set_temperature(int temperature) throws TemperatureSetterError;
	}

	class RedshiftTemperatureSetter : GLib.Object, ITemperatureSetter {

		public void set_temperature(int temperature) throws TemperatureSetterError {
			string command = "redshift -O " + temperature.to_string() + "K";
			try {
				execute_command(command);
			} catch (CommandRunError e) {
				throw new TemperatureSetterError.CANNOT_EXECUTE_DOMMAND(e.message);
			}
		}

	}

}
