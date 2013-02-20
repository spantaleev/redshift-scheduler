namespace RedshiftScheduler {

	class TestRule : TestCase {

		public TestRule() {
			base("Rule");
			this.add_test("test_constructor", this.test_constructor);
			this.add_test("test_application_detection", this.test_application_detection);
			this.add_test("test_period_length_calculation", this.test_period_length_calculation);
			this.add_test("test_minutes_into_calculation", this.test_minutes_into_calculation);
		}

		public void test_constructor() {
			Rule r = new Rule(3500, true, new Time(14, 30), new Time(15, 26));
			this.assert(r.temperature == 3500);
			this.assert(r.transient == true);
			this.assert(r.start.hour == 14);
			this.assert(r.start.minute == 30);
			this.assert(r.end.hour == 15);
			this.assert(r.end.minute == 26);

			r = new Rule(6200, false, new Time(0, 12), new Time(2, 15));
			this.assert(r.temperature == 6200);
			this.assert(r.transient == false);
			this.assert(r.start.hour == 0);
			this.assert(r.start.minute == 12);
			this.assert(r.end.hour == 2);
			this.assert(r.end.minute == 15);
		}

		public void test_application_detection() {
			//Regular rule (that spans just 1 day)
			this.check_rule_application(new Time(12, 0), new Time(13, 0), false, new Time(11, 59));
			this.check_rule_application(new Time(12, 0), new Time(13, 0), true, new Time(12, 30));
			this.check_rule_application(new Time(12, 0), new Time(13, 0), true, new Time(12, 0));
			this.check_rule_application(new Time(12, 0), new Time(13, 0), true, new Time(12, 59));
			this.check_rule_application(new Time(12, 0), new Time(13, 0), false, new Time(13, 0));
			this.check_rule_application(new Time(12, 0), new Time(13, 0), false, new Time(20, 0));

			//Rule that spans 2 days
			this.check_rule_application(new Time(23, 30), new Time(2, 15), false, new Time(23, 29));
			this.check_rule_application(new Time(23, 30), new Time(2, 15), true, new Time(23, 30));
			this.check_rule_application(new Time(23, 30), new Time(2, 15), true, new Time(23, 59));
			this.check_rule_application(new Time(23, 30), new Time(2, 15), true, new Time(0, 0));
			this.check_rule_application(new Time(23, 30), new Time(2, 15), true, new Time(0, 15));
			this.check_rule_application(new Time(23, 30), new Time(2, 15), true, new Time(2, 14));
			this.check_rule_application(new Time(23, 30), new Time(2, 15), false, new Time(2, 15));
			this.check_rule_application(new Time(23, 30), new Time(2, 15), false, new Time(11, 50));

			this.check_rule_application(new Time(23, 30), new Time(23, 20), true, new Time(23, 35));
			this.check_rule_application(new Time(23, 30), new Time(23, 20), true, new Time(23, 59));
			this.check_rule_application(new Time(23, 30), new Time(23, 20), true, new Time(0, 0));
			this.check_rule_application(new Time(23, 30), new Time(23, 20), true, new Time(8, 37));
			this.check_rule_application(new Time(23, 30), new Time(23, 20), true, new Time(23, 15));
			this.check_rule_application(new Time(23, 30), new Time(23, 20), true, new Time(23, 19));
			this.check_rule_application(new Time(23, 30), new Time(23, 20), false, new Time(23, 20));
		}

		public void test_period_length_calculation() {
			//Regular rules (that span just 1 day)
			this.check_rule_period_length(new Time(3, 8), new Time(3, 8), 1);
			this.check_rule_period_length(new Time(3, 8), new Time(3, 9), 1);
			this.check_rule_period_length(new Time(3, 0), new Time(3, 0), 1);
			this.check_rule_period_length(new Time(3, 0), new Time(3, 1), 1);

			this.check_rule_period_length(new Time(12, 0), new Time(13, 0), 60);
			this.check_rule_period_length(new Time(4, 0), new Time(6, 0), 120);
			this.check_rule_period_length(new Time(4, 2), new Time(6, 0), 118);
			this.check_rule_period_length(new Time(4, 0), new Time(6, 3), 123);
			this.check_rule_period_length(new Time(4, 3), new Time(6, 4), 121);
			this.check_rule_period_length(new Time(3, 58), new Time(4, 0), 2);
			this.check_rule_period_length(new Time(3, 58), new Time(4, 2), 4);
			this.check_rule_period_length(new Time(15, 59), new Time(16, 0), 1);
			this.check_rule_period_length(new Time(3, 58), new Time(6, 4), 126);

			//Rules that span 2 days
			this.check_rule_period_length(new Time(23, 59), new Time(0, 3), 4);
			this.check_rule_period_length(new Time(23, 58), new Time(0, 3), 5);
			this.check_rule_period_length(new Time(23, 30), new Time(1, 15), 105);
			this.check_rule_period_length(new Time(23, 30), new Time(22, 30), (23 * 60));
			this.check_rule_period_length(new Time(23, 30), new Time(23, 20), (24 * 60 - 10));
		}

		public void test_minutes_into_calculation() {
			this.check_minutes_into(new Time(23, 0), new Time(23, 15), new Time(23, 0), 0);
			this.check_minutes_into(new Time(23, 0), new Time(23, 15), new Time(23, 3), 3);

			this.check_minutes_into(new Time(23, 0), new Time(0, 15), new Time(0, 0), 60);
			this.check_minutes_into(new Time(23, 0), new Time(0, 15), new Time(0, 5), 65);

			this.check_minutes_into(new Time(23, 30), new Time(23, 25), new Time(23, 20), (24 * 60 - 10));
		}

		private void check_rule_application(Time start, Time end, bool should_apply, Time at_time) {
			Rule r = new Rule(3000, false, start, end);
			this.assert(
				r.applies_at_time(at_time) == should_apply,
				"Rule `%s` %s `%s`".printf(
					r.to_string(),
					(should_apply ? "applies at" : "does not apply at"),
					at_time.to_string()
				)
			);
		}

		private void check_rule_period_length(Time start, Time end, int length_minutes) {
			Rule r = new Rule(3000, false, start, end);
			this.assert(
				r.get_length_minutes() == length_minutes,
				"Rule length for `%s` is %d (got %d)".printf(
					r.to_string(),
					length_minutes,
					r.get_length_minutes()
				)
			);
		}

		private void check_minutes_into(Time start, Time end, Time at_time, int minutes) {
			Rule r = new Rule(3000, false, start, end);
			this.assert(
				r.get_minutes_into(at_time) == minutes,
				"%s is %d minutes into %s (got %d)".printf(
					at_time.to_string(),
					minutes,
					r.to_string(),
					r.get_minutes_into(at_time)
				)
			);
		}

	}

}
