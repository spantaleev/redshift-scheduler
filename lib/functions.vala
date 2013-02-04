namespace RedshiftScheduler {

	void dump_rules(Rule[] rules) {
		foreach (Rule r in rules) {
			message("\tRule %s", r.to_string());
		}
	}

}
