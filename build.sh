#!/bin/bash

valac --pkg gio-2.0 --target-glib=2.34 redshift-scheduler.vala lib/*.vala

exit $?
