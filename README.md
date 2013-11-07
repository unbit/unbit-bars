unbit-bars
==========

A Perl Curses::UI interface for uWSGI metrics subsystem

![ScreenShot](https://raw.github.com/unbit/unbit-bars/master/screenshot.png)

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

Currently the metrics can be gathered in 2 ways:

'stats' => get the values from a uWSGI stats server

'udp' => bind to a udp address and wait for updates directly sent by a uWSGI server

Examples (stats mode)
---------------------

```sh
uwsgi --http-socket :9090 --processes 2 --stats :9393 --psgi yourapp.pl
```

```sh
perl bars.pl --addr 127.0.0.1:9393 worker.0.requests:2000:450 worker.1.requests:1000 worker.2.requests:1000
```

this will start gathering 3 metrics (with the first one with a threshold of 450)


Examples (udp mode)
-------------------

```sh
uwsgi --http-socket :9090 --processes 2 --stats-push socket:127.0.0.1:9292  --psgi yourapp.pl
```


```sh
perl bars.pl --mode udp --addr 127.0.0.1:9292 uwsgi.worker.0.requests:2000:450 uwsgi.worker.1.requests:1000 uwsgi.worker.2.requests:1000
```

this time we bind to udp port 9292 and instruct uWSGI to 'push' metrics to this address.

Pay attention, stats pushers add a prefix to each metric ('uwsgi' in such a case), remember it !!!

Options
-------

--freq => set the update frequency

--mode => set the mode ('udp' or 'stats')

--addr => set the address

metric:max:threshold => you can specify all the metrics you need, max and threshold are optionals. By default a max of 100 is assumed
