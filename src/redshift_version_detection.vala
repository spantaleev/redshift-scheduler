namespace RedshiftScheduler {

	public errordomain VersionDetectionError {
		UNRECOGNIZED_VERSION,
		CANNOT_DETERMINE
	}

	struct VersionInformation {
		int major;
		int minor;
	}

	VersionInformation detect_redshift_version() throws VersionDetectionError {
		try {
			string output = execute_command("redshift -V");
			return parse_redshift_version_from_output(output);
		} catch (CommandRunError e) {
			throw new VersionDetectionError.CANNOT_DETERMINE(e.message);
		}
	}

	VersionInformation parse_redshift_version_from_output(string versionOutput) throws VersionDetectionError {
		try {
			Regex regex = new Regex("^redshift ([0-9]+)\\.([0-9]+)");
			MatchInfo match;
			if (regex.match(versionOutput, RegexMatchFlags.NOTEMPTY, out match)) {
				VersionInformation v = VersionInformation();
				v.major = int.parse(match.fetch(1));
				v.minor = int.parse(match.fetch(2));
				return v;
			}
			throw new VersionDetectionError.UNRECOGNIZED_VERSION("Unrecognized version for: %s".printf(versionOutput));
		} catch (RegexError e) {
			throw new VersionDetectionError.CANNOT_DETERMINE(e.message);
		}
	}

}