#!/bin/bash

mkdir build -p

valac -X -w --disable-warnings --pkg gio-2.0 --pkg posix --target-glib=2.34 -o build/tests-runner src/*.vala tests/*.vala

if [  $? -eq 0 ]; then
	build/tests-runner
	exit $?
fi

exit $?
