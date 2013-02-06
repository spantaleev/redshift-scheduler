namespace RedshiftScheduler {

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
			Time start = this.start;
			Time end = this.end;

			return (
				(start.hour < time.hour || (start.hour == time.hour && time.minute >= start.minute))
				&&
				(time.hour < end.hour || (end.hour == time.hour && time.minute <= end.minute))
			);
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
