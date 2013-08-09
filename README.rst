Redshift Scheduler
==================

**redshift-scheduler**, as the name implies is a scheduler program for `redshift <http://jonls.dk/redshift/>`_.

Redshift adjusts the color temperature of your screen according to your surroundings (meaning according to the time of day and your location).
This may help your eyes hurt less if you are working in front of the screen at night.

However, not everyone has the same day-schedule and likes their screen "turning red" at ~17:00 in the afternoon.



What does it do?
----------------

Read the description over at `redshift's page <http://jonls.dk/redshift/>`_ for an introduction to the general idea of "screen temperature changing".

You can then determine whether **redshift** is good enough for you, or you need the advanced control that **redshift-scheduler** offers.



What problems with redshift does this fix?
------------------------------------------

**redshift-scheduler** addresses the following problems with the way **redshift** works:

1. No sane control over the screen temperature over the day
    - **redshift** uses the time of day and your location to "magically" determine a temperature value (which you might not *always* like)
    - **redshift-scheduler** gives you a way configure the exact temperature and temperature transitions at any time of the day

2. No control over how gradually the temperature changes
    - **redshift**'s temperature transitions are somewhat fast (strikingly visible and thus, annoying)
    - **redshift-scheduler**'s temperature transitions can be very gradual (invisible to the user)



How does it work?
-----------------

**redshift-scheduler** uses a configuration file that specifies a number of rules.
Rules define time periods within the day and their corresponding temperature (or temperature transition).

Generally, rules state something like this:
    - from 11:00 to 18:00, I'd like the maximum screen temperature (6500K)
    - from 18:00 to 20:00, I'd like a gradual decrease from 6500K to 5000K
    - from 20:00 to 23:30, I'd like a gradual decrease from 5000K to 4500K
    - etc.

To learn more, see the sample/default rules file (in the ``resources/`` directory).

**redshift-scheduler** calculates the temperature at any given moment of the day and periodically invokes **redshift** to apply it.
Therefore, you need **redshift** installed as well.



Installation
------------

A package for `ArchLinux <http://archlinux.org>`_ is available `here <https://aur.archlinux.org/packages/redshift-scheduler/>`_.
Contributions, so that packages for other distros can be made, are always welcome.



Manual Installation
-------------------

**redshift-scheduler** is written in `Vala <https://live.gnome.org/Vala>`_ and compiles to native code.

Build from source (requires: ``vala``, ``glib2`` and ``libgee``)::

    ./build.sh

The ``redshift-scheduler`` executable would appear in the newly created ``build/`` directory.
Copy the ``redshift-scheduler`` executable file anywhere you'd like.

Copy the default rules file (``resources/rules.conf.dist``) to ``~/.config/redshift-scheduler/rules.conf``.

Make sure you have `redshift <http://jonls.dk/redshift/>`_ installed, as **redshift-scheduler** depends on it.


For distro packagers
--------------------

A package would:
    - build the executable and stage it for copying to /usr/bin/ or some other location
    - stage ``resources/rules.conf.dist`` (the default config) for copying to ``/usr/share/redshift-scheduler/rules.conf.dist``

Dependencies:
    - `Vala <https://live.gnome.org/Vala>`_
    - glib2
    - `Libgee <https://live.gnome.org/Libgee>`_
    - the ``redshift`` binary on the path



Usage
-----

The program is meant to start and run with user privileges.
You can set it up to start on desktop environment start-up (with ``gnome-session-properties``, ``xfce4-session-settings``, etc.)

The first time you can run ``redshift-scheduler`` from the command-line.
During that first start, ``~/config/redshift-scheduler/rules.conf`` will be created, based on the default configuration at ``/usr/share/redshift-scheduler/rules.conf.dist``.

**redshift-scheduler** runs during the day and controls the screen temperature according to the rules in ``~/config/redshift-scheduler/rules.conf``.

Rules can be customized to your liking. Rule changes take effect immediately (without needing a program restart).



Ideas/future developments
-------------------------

- The ability to temporarily disable temperature changes ("stop for 1 hour", etc.)

- A GUI tray program that allows certain features of **redshift-scheduler** to be controlled with the mouse (disabling temporarily, showing the current temperature)
