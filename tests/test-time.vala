namespace RedshiftScheduler {

	class TestTime : TestCase {

		public TestTime() {
			base("Time");
			this.add_test("test_constructor", this.test_constructor);
			this.add_test("test_constructor_from_minutes", this.test_constructor_from_minutes);
			this.add_test("test_minutes_conversion", this.test_minutes_conversion);
			this.add_test("test_string_representation", this.test_string_representation);
		}

		public void test_constructor() {
			this.assert_time(new Time(13, 45), 13, 45);
		}

		public void test_constructor_from_minutes() {
			this.assert_time(new Time.from_minutes(0), 0, 0);
			this.assert_time(new Time.from_minutes(10), 0, 10);
			this.assert_time(new Time.from_minutes(75), 1, 15);

			this.assert_time(new Time.from_minutes(-10), 23, 50);
			this.assert_time(new Time.from_minutes(-1), 23, 59);
		}

		public void test_minutes_conversion() {
			this.assert_minutes_conversion(new Time(0, 0), 0);
			this.assert_minutes_conversion(new Time(0, 10), 10);

			this.assert_minutes_conversion(new Time(1, 0), 60);
			this.assert_minutes_conversion(new Time(1, 15), 75);

			this.assert_minutes_conversion(new Time(23, 59), (23 * 60 + 59));
		}

		public void test_string_representation() {
			this.assert_string_representation(new Time(0, 0), "00:00");
			this.assert_string_representation(new Time(1, 25), "01:25");
			this.assert_string_representation(new Time(14, 5), "14:05");
		}

		private void assert_time(Time time, int hour, int minute) {
			this.assert(hour == time.hour);
			this.assert(minute == time.minute);
		}

		private void assert_minutes_conversion(Time time, int total_minutes) {
			this.assert(
				time.to_minutes() == total_minutes,
				"%s to minutes is %d (got %d)".printf(time.to_string(), total_minutes, time.to_minutes())
			);
		}

		private void assert_string_representation(Time time, string str) {
			this.assert(time.to_string() == str);
		}

	}

}
