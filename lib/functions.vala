namespace RedshiftScheduler {

	public errordomain CommandRunError {
		SPAWN_FAILURE,
		EXIT_STATUS
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

	void dump_rules(Rule[] rules) {
		foreach (Rule r in rules) {
			message("\tRule %s", r.to_string());
		}
	}

}
