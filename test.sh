#!/bin/bash

valac -X -w --disable-warnings --pkg gio-2.0 --target-glib=2.34 -o tests/tests-runner src/*.vala tests/*.vala

if [  $? -eq 0 ]; then
	tests/tests-runner
	exit $?
fi

exit $?
