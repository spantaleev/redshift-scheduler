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

	bool create_file_from_template(File file, string template_file_name) {
		string[] data_dirs = {GLib.Environment.get_user_data_dir()};
		foreach (string d in GLib.Environment.get_system_data_dirs()) {
			data_dirs += d;
		}

		foreach (string data_path in data_dirs) {
			string template_file_path = Path.build_path("/", data_path, "/redshift-scheduler/", template_file_name);

			debug("Looking for file: %s", template_file_path);

			File template = File.new_for_path(template_file_path);
			if (!template.query_exists()) {
				continue;
			}

			try {
				debug("Copying `%s` to `%s`", template_file_path, file.get_path());
				return template.copy(file, FileCopyFlags.NONE);
			} catch (Error e) {
				debug(e.message);
				return false;
			}
		}
		return false;
	}


}
