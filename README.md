unbit-bars
==========

A Perl Curses::UI interface for uWSGI metrics subsystem

About
-----

This terminal interface allows you to monitor (in almost-realtime) values gathered/collected from the uWSGI metric subsystem.

You can monitor multiple metrics, each one will be showed as a Curses::UI::Progressbar

For each metric you can define a maximum value and a 'threshold' value. Metrics with a value higher than the specified threshold
will be showed in red

Requirements
------------

The only additional requirement is the Curses::UI module.

```sh
cpanm Curses::UI
```

Operational modes
-----------------

Currently the metrcis can be gathered in 2 ways:

'stats' => get the values from a uWSGI stats server

'udp' => bind to a udp address and wait for updates directly sent by a uWSGI server
