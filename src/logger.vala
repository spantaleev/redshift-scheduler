namespace RedshiftScheduler {

	interface ILogger : GLib.Object {
		public abstract void install();
	}

	class StandardLogger : GLib.Object, ILogger {

		private bool debug;

		public StandardLogger(bool debug) {
			this.debug = debug;
		}

		public void install() {
			Log.set_default_handler((log_domain, flags, message) => {
				if (!this.debug && flags == LogLevelFlags.LEVEL_DEBUG) {
					return;
				}

				string message_type = flags.to_string();
				if (message_type == null) {
					//This happens when fatal errors are encountered.
					message_type = "error";
				} else {
					message_type = message_type.replace("G_LOG_LEVEL_", "").down();
				}

				stdout.printf("[%s] %s\n", message_type, this.format_message(message));
			});
		}

		private string format_message(string message) {
			if (this.debug) {
				return message;
			}

			try {
				Regex regex = new Regex("^(?:.+?)\\.vala:(?:[0-9]+): (.+?)$");
				MatchInfo match;
				if (regex.match(message, RegexMatchFlags.NOTEMPTY, out match)) {
					return match.fetch(1);
				}
			} catch (RegexError e) {

			}
			return message;
		}

	}

}
