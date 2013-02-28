#!/bin/bash

mkdir build -p

valac -X -w --pkg gio-2.0 --pkg posix --target-glib=2.34 -o build/redshift-scheduler redshift-scheduler.vala src/*.vala

exit $?
