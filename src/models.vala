namespace RedshiftScheduler {

	/**
	 * Represents a rule (period, temperature and transition type).
	 *
	 * Rules represent a time period which is not inclusive at the end.
	 * E.g. 14:35 to 14:38 applies at minutes 35, 36 and 37 (but not for 38).
	 *
	 * Rules that are instances of this class may represent a period spanning 2 days (23:55 -> 00:10).
	 * Special care is taken to ensure calculations work in those cases.
	 */
	class Rule {

		public const int TEMPERATURE_MAX = 6500;
		public const int TEMPERATURE_MIN = 1000;

		public int temperature { get; private set; }
		public bool transient { get; private set; }
		public Time start { get; private set; }
		public Time end { get; private set; }

		public Rule(int temperature, bool transient, Time start, Time end)
				requires (temperature >= TEMPERATURE_MIN && temperature <= TEMPERATURE_MAX) {
			this.temperature = temperature;
			this.transient = transient;
			this.start = start;
			this.end = end;
		}

		public bool applies_at_time(Time time) {
			foreach (DayConfinedRule r in this.get_day_confined_rules()) {
				if (r.applies_at_time(time)) {
					return true;
				}
			}
			return false;
		}

		public int get_length_minutes() {
			int total_minutes = 0;
			foreach (DayConfinedRule r in this.get_day_confined_rules()) {
				total_minutes += r.get_length_minutes();
			}
			return total_minutes;
		}

		public int get_minutes_into(Time time) {
			int total = 0;
			int ruleNumber = 0;

			foreach (DayConfinedRule rule in this.get_day_confined_rules()) {
				ruleNumber += 1;

				int increment = 0;

				if (rule.applies_at_time(time)) {
					increment = rule.get_minutes_into(time);
				} else if (ruleNumber == 1) {
					//The first day of the rule does not apply, meaning we're definitely into
					//the second day of the rule and the first has passed completely.
					increment = rule.get_length_minutes();
				}

				total += increment;
			}

			return total;
		}

		public string to_string() {
			return "%s %s %s | %dK".printf(this.start.to_string(), (this.transient ? "->" : "--"), this.end.to_string(), this.temperature);
		}

		private bool spans_multiple_days() {
			return (
				(this.end.hour < this.start.hour)
				||
				(this.start.hour == this.end.hour && this.end.minute < this.start.minute)
			);
		}

		/**
		 * Splits a rule into one or more day-confined rules.
		 *
		 * Rules that don't span multiple days are simply represented by a single day-confined rule.
		 *
		 * Rules that span multiple days are split into 2 day-confined rules.
		 * The first day-confined rule is marked as "end-inclusive", which is important.
		 * 23:50 -> 00:10 gets split into 23:50 to 23:59 (inclusive) and 00:00 to 00:10 (non-inclusive)
		 */
		private DayConfinedRule[] get_day_confined_rules() {
			if (!this.spans_multiple_days()) {
				return {
					new DayConfinedRule(this.temperature, this.transient, this.start, this.end, false)
				};
			}

			DayConfinedRule[] day_confined_rules = {};
			day_confined_rules += new DayConfinedRule(this.temperature, this.transient, this.start, new Time(23, 59), true);
			day_confined_rules += new DayConfinedRule(this.temperature, this.transient, new Time(0, 0), this.end, false);
			return day_confined_rules;
		}

	}


	/**
	 * Represents a rule that is confined to a single day
	 * (unlike instances of the base Rule class that may span multiple days).
	 */
	class DayConfinedRule : Rule {

		private bool end_is_inclusive;

		public DayConfinedRule(int temperature, bool transient, Time start, Time end, bool end_is_inclusive)
				requires (start.hour <= end.hour) {
			base(temperature, transient, start, end);
			this.end_is_inclusive = end_is_inclusive;
		}

		/**
		 * Tells whether this day-confined rule applies at the given time.
		 *
		 * The period's end time of this rule may or may not be inclusive.
		 * Day-confined rules rarely use an inclusive end time
		 * (only when they represent a regular Rule split into 2).
		 */
		public new bool applies_at_time(Time time) {
			Time start = this.start;
			Time end = this.end;

			bool is_after_start = (start.hour < time.hour || (start.hour == time.hour && time.minute >= start.minute));
			bool is_before_end;
			if (this.end_is_inclusive) {
				is_before_end = (time.hour < end.hour || (end.hour == time.hour && time.minute <= end.minute));
			} else {
				is_before_end = (time.hour < end.hour || (end.hour == time.hour && time.minute < end.minute));
			}

			return (is_after_start && is_before_end);
		}

		public new int get_length_minutes() {
			int length = this.end.to_minutes() - this.start.to_minutes();

			if (this.start.to_string() == this.end.to_string() || this.end_is_inclusive) {
				//15:35 to 15:35 is 1 minute (15:35)
				//15:35 to 15:36 is 1 minute as well (15:35).
				//23:59 to 00:03 is 4 minutes (59, 00, 01, 02)
				//23:58 to 00:03 is 5 minutes (58, 59, 00, 01, 02) - inclusive end here makes a change!
				length += 1;
			}

			return length;
		}

		public new int get_minutes_into(Time time) {
			return time.to_minutes() - this.start.to_minutes();
		}

	}

	class Time {

		public int hour { get; private set; }
		public int minute { get; private set; }

		public Time(int hour, int minute)
				requires (hour >= 0 && hour <= 24)
				requires (minute >= 0 && minute <= 60) {
			this.hour = hour;
			this.minute = minute;
		}

		public Time.from_minutes(int minutes) {
			if (minutes < 0) {
				//Creating from "negative minutes" is supported. (`-10` minutes means 23:50)
				minutes = (24 * 60) + minutes;
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

	}

}
