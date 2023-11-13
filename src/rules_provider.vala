namespace RedshiftScheduler {

	public errordomain RulesError {
		GENERIC_FAILURE,
		FILE_MISSING,
		FILE_READ
	}

	interface IRulesProvider : GLib.Object {
		public abstract Rule[] get_rules() throws RulesError;

		/**
		 * Signal to notify rules consumers that new rules might be available.
		 */
		public signal void rules_outdated();
	}

	class FileRulesProvider : GLib.Object, IRulesProvider {

		public File file { get; private set; }

		public FileRulesProvider(File file) {
			this.file = file;
		}

		public Rule[] get_rules() throws RulesError {
			return FileRulesProvider.read_rules_from_file(this.file);
		}

		private static Rule[] read_rules_from_file(File file) throws RulesError {
			Rule[] rules = {};

			MatchInfo match;
			Regex ruleRegex;

			try {
				ruleRegex = new Regex("^([0-9]+):([0-9]+) (--|->) ([0-9]+):([0-9]+) \\| ([0-9]+)K?");
			} catch (RegexError e) {
				throw new RulesError.GENERIC_FAILURE("Cannot create regex.");
			}

			if (!file.query_exists()) {
				throw new RulesError.FILE_MISSING("File is missing.");
			}

			try {
				var dis = new DataInputStream(file.read());
				string line;
				while ((line = dis.read_line(null)) != null) {
					if (line == "" || line.has_prefix("#")) {
						//Ignore empty or comment lines
						continue;
					}

					if (!ruleRegex.match(line, RegexMatchFlags.NOTEMPTY, out match)) {
						warning("The line `%s` contains an invalid rule (bad syntax?).", line);
						continue;
					}

					Time time_start = new Time(int.parse(match.fetch(1)), int.parse(match.fetch(2)));
					bool transient = (match.fetch(3) == "->");
					Time time_end = new Time(int.parse(match.fetch(4)), int.parse(match.fetch(5)));
					int temperature = int.parse(match.fetch(6));

					if (time_start == null || time_end == null) {
						//Happens when Time object construction fails (`requires` clauses not satisfied).
						warning("The time period in rule `%s` is invalid. Skipping rule.", line);
						continue;
					}

					if (temperature < TEMPERATURE_MIN) {
						warning("The rule `%s` specifies a temperature that is too low. Using %dK instead.", line, TEMPERATURE_MIN);
						temperature = TEMPERATURE_MIN;
					}

					if (TEMPERATURE_MAX < temperature) {
						warning("The rule `%s` specifies a temperature that is too high. Using %dK instead.", line, TEMPERATURE_MAX);
						temperature = TEMPERATURE_MAX;
					}

					rules += new Rule(temperature, transient, time_start, time_end);
				}
			} catch (IOError e) {
				throw new RulesError.FILE_READ(e.message);
			} catch (Error e) {
				throw new RulesError.GENERIC_FAILURE(e.message);
			}

			return rules;
		}

	}

	class LiveFileRulesProvider : GLib.Object, IRulesProvider {

		private FileRulesProvider provider;
		private Rule[] rules;
		private bool rules_loaded = false;

		public LiveFileRulesProvider(FileRulesProvider provider) {
			this.provider = provider;
			this.setup_rules_reloader();
		}

		private void setup_rules_reloader() {
			try {
				new Thread<void*>.try("reloader", () => {
					try {
						FileMonitor monitor = this.provider.file.monitor_file(FileMonitorFlags.NONE, null);
						monitor.changed.connect((src, dest, event) => {
							if (event == FileMonitorEvent.CREATED) {
								try {
									Rule[] rules = this.provider.get_rules();

									lock(this.rules) {
										this.rules = rules;
									}

									message("Rules reloaded");
									dump_rules(rules);

									this.rules_outdated();
								} catch (RulesError e) {
									warning("Failed while reloading rules: %s", e.message);
								}
							}
						});

						new MainLoop().run();
					} catch (Error e) { }

					return null;
				});
			} catch (Error e) {
				critical("Thread error");
			}
		}

		public Rule[] get_rules() throws RulesError {
			if (! this.rules_loaded) {
				try {
					lock(this.rules) {
						this.rules = this.provider.get_rules();
						this.rules_loaded = true;
						debug("Rules initially loaded");
						dump_rules(this.rules);
					}
				} catch (GLib.Error e) {
					warning("Failed while locking: %s", e.message);
					throw new RulesError.GENERIC_FAILURE(e.message);
				}
			}
			return this.rules;
		}

	}

}
