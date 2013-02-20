namespace RedshiftScheduler {

	int main(string[] args) {
		Test.init(ref args);
		TestSuite.get_root().add_suite(new TestTime().get_suite());
		TestSuite.get_root().add_suite(new TestRule().get_suite());
		return Test.run();
	}

}
