namespace RedshiftScheduler {

	public errordomain TemperatureSetterError {
		CANNOT_EXECUTE_DOMMAND
	}

	public errordomain CommandRunError {
		SPAWN_FAILURE,
		EXIT_STATUS
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

	string execute_command(string command) throws CommandRunError {
		try {
			string std_out;
			string std_err;
			int status;

			Process.spawn_command_line_sync(command, out std_out, out std_err, out status);

			string complete_output = std_out + std_err;

			if (status != 0) {
				throw new CommandRunError.EXIT_STATUS("Command `%s` exited with status `%d`: %s", command, status, complete_output);
			}

			return complete_output;
		} catch (SpawnError e) {
			throw new CommandRunError.SPAWN_FAILURE(e.message);
		}
	}

}
