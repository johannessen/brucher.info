brucher-info transit
====================

Considering its rural location, the Brucher Talsperre has very decent
public transport service. However, the timetables are set up in such a way
that it is very difficult to actually use public transport efficiently.

In particular, the Brucher Talsperre is serviced by four different bus
routes, all of which run on an irregular schedule and have different
stopping patterns, so that memorising timings is unfeasible. However,
between these four routes, only two route numbers are used. As an
additional complication, frequently stops are used multiple times by
the same service. These issues make it essentially impossible to use
public transit apps to quickly find when and where the next service
will leave when travelling *from* Brucher Talsperre.

Given that the timetables had recently been offered as open data, these
scripts piloted a web service to answer this specific question. The web
service was operational in 2017–2018, but hasn't been updated since and
is currently not deployed anywhere. It is unknown if it still works with
today's timetable data without modification.


Design
------

Since we are only interested in a tiny portion of the timetable, the
relevant data is cached before use. The `gtfs-brucher.sql` script prepares
the database accordingly. Some stop IDs are hard-coded, but this is only
done to provide more useful stop names *if available* and should not cause
trouble if the IDs change with future datasets.

The web front-end is a simple Mojolicious app that runs a query on the
cached data and presents the result to the user in the form of a departure
display not for any single stop or route, but for the Brucher Talsperre
as a common location.

In particular, this means that in addition to the *time* of the next
departure, an indication of the *location* of that departure will be given.
The location depends on whether or not it is an express (“Schnellbus”)
service, and whether or not the town of Müllenbach is serviced.


See Also
--------

* [VRS OpenData GTFS (soll)](https://www.vrsinfo.de/fahrplan/oepnv-daten-fuer-webentwickler.html)
* [Google Transit API Reference](https://developers.google.com/transit/gtfs/reference/)
* [GTFS class diagram](https://opentransportdata.swiss/wp-content/uploads/2016/11/gtfs_static.png)
* [Stackoverflow – How can I make my GTFS queries run faster?](https://stackoverflow.com/questions/25750057/how-can-i-make-my-gtfs-queries-run-faster)


Installation
------------

In 2017, the following steps would successfully prepare the database cache
as `vrs`:

````bash
curl -LO https://download.vrsinfo.de/gtfs/google_transit.zip
# next step will unzip into CURRENT dir!
unzip google_transit.zip
for f in calendar_dates.txt feed_info.txt transfers.txt
do  # append auto_increment column
  sed -e 's/$/,0/' -i~ "$f"
done
for f in stop_times.txt trips.txt
do  # append auto_increment column AND make previous column NULL
  sed -e 's/$/\\N,0/' -i~ "$f"
done
rm google_transit.zip *.txt~

# run as root:
mkdir -p /var/lib/mysql-files
mysql vrs < ./gtfs-vrs.sql
for f in *.txt
do
  ln -f "$f" "/var/lib/mysql-files/$f"
  mysqlimport --delete \
    --fields-terminated-by=',' --fields-optionally-enclosed-by='"' --ignore-lines=1 \
    vrs "/var/lib/mysql-files/$f"
  rm -f "/var/lib/mysql-files/$f"
done
mysql vrs < ./gtfs-brucher.sql
````

For this to work, `/etc/my.cnf` will need to contain:

````
[mysqld]
secure-file-priv = "/var/lib/mysql-files"
````


Copying
-------

You may reuse these scripts under the terms of the ISC License
or (at your option) the Artistic License 2.0.

Copyright (c) 2017-2018, Arne Johannessen
