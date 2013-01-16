namespace RedshiftScheduler {

	public errordomain TemperatureDeterminerError {
		GENERIC_FAILURE
	}

	interface ITemperatureDeterminer : GLib.Object {
		public abstract int determine_temperature() throws TemperatureDeterminerError;
	}

	class RulesBasedTemperatureDeterminer : GLib.Object, ITemperatureDeterminer {

		private IRulesProvider rules_provider;

		public RulesBasedTemperatureDeterminer(IRulesProvider rules_provider) {
			this.rules_provider = rules_provider;
		}

		public int determine_temperature() throws TemperatureDeterminerError {
			DateTime dt_now = new DateTime.now_local();
			Time time = new Time(dt_now.get_hour(), dt_now.get_minute());

			RulesCollection rules;

			try {
				rules = this.rules_provider.get_rules();
			} catch (RulesError e) {
				throw new TemperatureDeterminerError.GENERIC_FAILURE("Cannot load rules: %s", e.message);
			}

			message("Looking for a rule applying at: %s", time.to_string());

			Rule? active_rule = rules.get_active(time);
			if (active_rule == null) {
				//Don't fail. No rules for the given period means "maximum temperature".
				active_rule = new Rule(Rule.TEMPERATURE_MAX, false, new Time(0, 0), new Time(23, 59));
				message("Assuming rule %s", active_rule.to_string());
			} else {
				message("Using rule %s", active_rule.to_string());
			}


			Rule? previous_rule = rules.get_previous(active_rule);
			if (previous_rule == null) {
				//Create a fake rule. The start/end times and the transient value are not important.
				previous_rule = new Rule(Rule.TEMPERATURE_MAX, false, new Time(0, 0), new Time(0, 0));
				warning(
					"Cannot determine previous rule of: `%s` (one matching for the time period before it)",
					active_rule.to_string()
				);
				debug("Assuming previous rule %s", previous_rule.to_string());
			} else {
				debug("Previous rule %s", previous_rule.to_string());
			}

			return this.calculate_temperature_by_rules(previous_rule, active_rule, time);
		}

		private int calculate_temperature_by_rules(Rule previous, Rule current, Time now) {
			if (! current.transient) {
				//The current period is not transient, meaning the temperature is constant
				//throughout the whole period, without gradual changes.
				return current.temperature;
			}

			//For transient periods, we use the previous rule to figure out the starting temperature.
			//The current rule gives us the end temperature.
			//We're somewhere in the current period, so the temperature we need to set is somewhere
			//between those two. The longer the period, the more gradually the temperature increases with time.

			int temp_difference = (previous.temperature - current.temperature).abs();

			int minutes_into_the_period = now.to_minutes() - current.start.to_minutes();

			double step = (double)temp_difference / current.get_length_minutes();

			int diff = (int)(step * (double)minutes_into_the_period);

			if (previous.temperature > current.temperature) {
				return previous.temperature - diff;
			}

			return previous.temperature + diff;
		}

	}

}
