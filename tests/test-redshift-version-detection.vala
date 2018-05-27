namespace RedshiftScheduler {

	class TestRedshiftVersionDetection : TestCase {

		public TestRedshiftVersionDetection() {
			base("RedshiftVersionDetection");
			this.add_test("test_version_detection", this.test_version_detection);
			this.add_test("test_version_detection_faults", this.test_version_detection_faults);
		}

		public void test_version_detection() {
			VersionInformation v;

			v = parse_redshift_version_from_output("redshift 1.11");
			this.assert(v.major == 1 && v.minor == 11);

			v = parse_redshift_version_from_output("redshift 12.31");
			this.assert(v.major == 12 && v.minor == 31);

			v = parse_redshift_version_from_output("redshift 14.35-dev");
			this.assert(v.major == 14 && v.minor == 35);
		}

		public void test_version_detection_faults() {
			try {
				parse_redshift_version_from_output("another");
				this.assert(false);
			} catch (VersionDetectionError.UNRECOGNIZED_VERSION e) {
				//Expected failure here.
			}
		}

	}
}
