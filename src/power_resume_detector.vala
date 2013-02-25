namespace RedshiftScheduler {

	interface IPowerResumeDetector : GLib.Object {
		public signal void resuming();
	}

	[DBus(name = "org.freedesktop.UPower")]
	interface UPower : GLib.Object {
		public signal void resuming();
	}

	class DBusPowerResumeDetector : GLib.Object, IPowerResumeDetector {

		public DBusPowerResumeDetector() {
			try {
				new Thread<void*>.try("detector", () => {
					try {
						UPower upower = Bus.get_proxy_sync(BusType.SYSTEM, "org.freedesktop.UPower", "/org/freedesktop/UPower");

						upower.resuming.connect(() => {
							this.resuming();
						});

						new MainLoop().run();
					} catch (Error e) {
						warning(e.message);
					}
					return null;
				});
			} catch (Error e) {
				critical("Thread error");
			}
		}

	}

}
