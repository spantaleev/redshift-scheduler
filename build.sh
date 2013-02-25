#!/bin/bash

valac -X -w --pkg gio-2.0 --target-glib=2.34 redshift-scheduler.vala src/*.vala

exit $?
