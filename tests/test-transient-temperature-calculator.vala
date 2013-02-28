namespace RedshiftScheduler {

	class TestTransientTemperatureCalculator : TestCase {

		public TestTransientTemperatureCalculator() {
			base("TransientTemperatureCalculator");
			this.add_test("test_calculator", this.test_calculator);
		}

		public void test_calculator() {
			Rule rule;

			//4000 -> 5200, gradual increase (20 K/sec.)
			rule = new Rule(5200, false, new Time(13, 0), new Time(14, 0));
			this.check_calc(rule, new Time(13, 0), 4000, 4000);
			this.check_calc(rule, new Time(13, 1), 4000, 4000 + 20);
			this.check_calc(rule, new Time(13, 30), 4000, 4600);
			this.check_calc(rule, new Time(13, 59), 4000, 5200 - 20);

			//4000 -> 4000, no transition
			rule = new Rule(4000, false, new Time(13, 0), new Time(14, 0));
			this.check_calc(rule, new Time(13, 30), 4000, 4000);

			//5200 -> 4000, gradual decrease (20 K/sec.)
			rule = new Rule(4000, false, new Time(13, 0), new Time(14, 0));
			this.check_calc(rule, new Time(13, 0), 5200, 5200);
			this.check_calc(rule, new Time(13, 1), 5200, 5200 - 20);
			this.check_calc(rule, new Time(13, 30), 5200, 4600);
			this.check_calc(rule, new Time(13, 59), 5200, 4000 + 20);
		}

		private void check_calc(Rule rule, Time time, int start_temperature, int expected) {
			int calculated = TransientRuleTemperatureCalculator.calculate_temperature_by_rule(rule, time, start_temperature);
			this.assert(calculated == expected, "Calculated temperature is %d (got %d)".printf(expected, calculated));
		}

	}

}

