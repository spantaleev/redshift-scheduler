namespace RedshiftScheduler {

	public errordomain TemperatureDeterminerError {
		GENERIC_FAILURE
	}

	interface ITemperatureDeterminer : GLib.Object {
		public abstract int determine_temperature() throws TemperatureDeterminerError;

		/**
		 * Signal to notify determiner consumers that the previously returned
		 * by determine_temperature() value is potentially outdated now.
		 */
		public signal void temperature_outdated();
	}

	class RulesBasedTemperatureDeterminer : GLib.Object, ITemperatureDeterminer {

		private IRulesProvider rules_provider;

		public RulesBasedTemperatureDeterminer(IRulesProvider rules_provider) {
			this.rules_provider = rules_provider;

			rules_provider.rules_outdated.connect(() => {
				this.temperature_outdated();
			});
		}

		public int determine_temperature() throws TemperatureDeterminerError {
			DateTime dt_now = new DateTime.now_local();
			Time time = new Time(dt_now.get_hour(), dt_now.get_minute());

			Rule[] rules;

			try {
				rules = this.rules_provider.get_rules();
			} catch (RulesError e) {
				throw new TemperatureDeterminerError.GENERIC_FAILURE("Cannot load rules: %s", e.message);
			}

			message("Looking for a rule applying at: %s", time.to_string());

			Rule? active_rule = this.determine_active_rule(rules, time);
			if (active_rule == null) {
				message("No rule found. Using maximum temperature (%dK)", TEMPERATURE_MAX);
				return TEMPERATURE_MAX;
			}

			message("Using rule %s", active_rule.to_string());

			if (!active_rule.transient) {
				//The current period is not transient, meaning the temperature is constant
				//throughout the whole period, without gradual changes.
				return active_rule.temperature;
			}

			Rule? previous_rule = this.determine_previous_rule(rules, active_rule);
			int start_temperature;
			if (previous_rule == null) {
				start_temperature = TEMPERATURE_MAX;
				warning("No previous rule of: `%s`. Assuming previous temperature: %dK", active_rule.to_string(), TEMPERATURE_MAX);
			} else {
				start_temperature = previous_rule.temperature;
				debug("Previous rule `%s`, with temperature: %dK", previous_rule.to_string(), start_temperature);
			}

			return TransientRuleTemperatureCalculator.calculate_temperature_by_rule(active_rule, time, start_temperature);
		}

		private Rule? determine_active_rule(Rule[] rules, Time time) {
			foreach (Rule rule in rules) {
				if (rule.applies_at_time(time)) {
					return rule;
				}
			}
			return null;
		}

		/**
		 * Returns the rule that was in effect right before (1 minute before)
		 * the one given.
		 */
		private Rule? determine_previous_rule(Rule[] rules, Rule current) {
			Time time = new Time.from_minutes(current.start.to_minutes() - 1);
			return this.determine_active_rule(rules, time);
		}

	}

	private class TransientRuleTemperatureCalculator {

		public static int calculate_temperature_by_rule(Rule current, Time now, int temperature_start) {
			//For transient periods, the current temperature is somewhere between the
			//start and end temperatures (depending on the time).
			//The longer the period, the more gradually the temperature changes with time.

			int temp_difference = (temperature_start - current.temperature).abs();

			int minutes_into_the_period = current.get_minutes_into(now);

			debug("%d minutes into the period", minutes_into_the_period);

			double step = (double)temp_difference / current.get_length_minutes();

			int diff = (int)(step * (double)minutes_into_the_period);

			if (current.temperature < temperature_start) {
				return temperature_start - diff;
			}

			return temperature_start + diff;
		}

	}

}
