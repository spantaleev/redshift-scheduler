# 1.3

Adds a `-p` flag which tells `redshift-scheduler` to print the temperature that it thinks should be set right now, calculated according to the given rules.

Note: `redshift-scheduler` prints the calculated temperature that corresponds to the given rules, and not the temperature currently set via `redshift`. If `redshift-scheduler` is not running, then there would obviously be a mismatch.


# 1.2

Adds support for redshift >= 1.12.

# 1.1

Be more quiet by default. To get more debug information, pass ``--debug``.

# 1.0

Initial release.
