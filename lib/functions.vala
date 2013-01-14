namespace RedshiftScheduler {

	void dump_rules(RulesCollection rules) {
		foreach (Rule r in rules.get_all()) {
			message("\tRule %s", r.to_string());
		}
	}

}
