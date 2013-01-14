namespace RedshiftScheduler {

	class RulesCollection {

		private Rule[] rules;

		public RulesCollection(Rule[] rules = {}) {
			this.rules = rules;
		}

		public Rule? get_active(Time time) {
			foreach (Rule rule in this.rules) {
				if (rule.applies_at_time(time)) {
					return rule;
				}
			}
			return null;
		}

		public Rule? get_previous(Rule current) {
			return this.get_active(Time.create_substracted_with_minutes(current.start, 1));
		}

		public Rule[] get_all() {
			return this.rules;
		}

	}

	class Rule {

		public const int TEMPERATURE_MAX = 6500;

		public int temperature { get; private set; }
		public bool transient { get; private set; }
		public Time start { get; private set; }
		public Time end { get; private set; }

		public Rule(int temperature, bool transient, Time start, Time end) {
			this.temperature = temperature;
			this.transient = transient;
			this.start = start;
			this.end = end;
		}

		public bool applies_at_time(Time time) {
			Time start = this.start;
			Time end = this.end;

			if (
					(start.hour < time.hour || (start.hour == time.hour && time.minute >= start.minute))
					&&
					(time.hour < end.hour || (end.hour == time.hour && time.minute <= end.minute))
				) {
				return true;
			}
			return false;
		}

		public int get_length_minutes() {
			int minutes = 0;
			minutes += 60 * (this.end.hour - this.start.hour);
			minutes -= this.start.minute;
			minutes += this.end.minute;
			return minutes;
		}

		public string to_string() {
			return "%s %s %s | %dK".printf(this.start.to_string(), (this.transient ? "->" : "--"), this.end.to_string(), this.temperature);
		}

	}

	class Time {

		public int hour { get; private set; }
		public int minute { get; private set; }

		public Time(int hour, int minute) {
			this.hour = hour;
			this.minute = minute;
		}

		public Time.from_minutes(int minutes) {
			if (minutes < 0) {
				minutes = (23 * 60) + 60 + minutes;
			}

			this.hour = (minutes / 60);
			this.minute = minutes - this.hour * 60;
		}

		public int to_minutes() {
			return this.hour * 60 + this.minute;
		}

		public string to_string() {
			return "%02d:%02d".printf(this.hour, this.minute);
		}

		public static Time create_substracted_with_minutes(Time time, int minutes_to_substract) {
			int total_minutes = time.hour * 60 + time.minute;
			int remaining_minutes = total_minutes - minutes_to_substract;

			return new Time.from_minutes(remaining_minutes);
		}

	}

}
