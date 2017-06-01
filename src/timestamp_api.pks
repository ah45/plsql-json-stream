/*
LPE Timestamp API
=================

## What

Conversion from timestamps in the local time zone to UTC.

See "The Rules of UTC Club" below for a quick reference guide.

## Why

Because the IFS database deals exclusively in timestamps relative to the
database/operating system time zone but doesn't actually _store_ the
values with the time zone information nor pass them to clients with it.

Essentially, you'd be forgiven for assuming the timestamps you get from
IFS are in UTC when they are not. This package makes it easy to set
your client timezone to UTC and convert timestamp values at the database
border.

### Please, tell me more

If your client doesn't do anything clever and you're only ever going to
be operating in a single time zone then the whole issue is moot, lucky
you. However, if your client does try to be clever, or you're just
particularly conscientious, then read on.

We'll consider the situation of a Java client retrieving date values
from the database. The following statements are usually true in this
scenario:

* The database server is set to a local time zone, `Europe/London` say.
* The client is running on a PC with the same (or a different!) time
  zone.
* Therefore, neither system is using strict UTC time.
* Doing a `select ...` for a `date` value against a view in IFS will
  result in the value being returned as a `java.sql.Timestamp`.
* **Being helpful**, JDBC will convert that value from the local time
  zone to UTC.

So, in that scenario--with both database and client using the
`Europe/London` time zone, during British Summer Time--when you have
the "date" `2015-04-09` your query, in Java, will actually return
`2015-04-08T23:00:00`.

Suddenly your "date" has shifted a day earlier.

Not ideal, but we can just set the client time zone to UTC and then it
won't mangle the dates, right? It'll just take them "as is". Yes, but...

This is equivalent to putting a snake in a cupboard, it'll come back to
bite you eventually.

#### OK, fine, what do we do then?

The only _safe_ way to deal with dates is to only ever communicate using
UTC time stamps. UTC out, UTC in; you can't go wrong.

But IFS cares not for your desire to use UTC. You should have thought
about that when you created the database because now you're stuck with
values recorded relative to what ever system time zone was in effect
at the time they were written.

(Say what? IFS stores all date/times/timestamps in `date` columns,
which don't retain any time zone information *and* only ever
originates new date/time values by calling `sysdate` which also has no
time zone information and is always relative to the _system_--not
database or session--timezone. See the [Oracle Time Zone
Support][otzs] documentation for further details.)

[otzs]: http://docs.oracle.com/cd/E11882_01/server.112/e10729/ch4datetime.htm

Oh, and the client just displays whatever the database sends it. In
another time zone? Tough, here's the time the transaction happened in
what ever time zone the server's in. Hope you know what that is and
what the conversion should be.

So we can't just retroactively decide to switch to UTC on the server.
(And God help you if you relocate or expand to a new time zone.)

But *our* clients, our clients can be built better, smarter, faster.
Which is where this API comes in.

UTC out, UTC in. No exceptions.

## The Rules of UTC Club

1. If you're given a date never treat it as anything other than a fixed
   reference to a day on a calendar.

2. Seriously, dates are _immutable_ I don't care what your time zone
   is/was, what _my_ time zone is/was, _it's always the same date_.

   (Note: working in the UTC timezone and using the
   `org.joda.time.LocalDate` class is perfect for this, you can't really
   done anything unsafe (other than convert to a full timestamp) with
   that.)

3. You may only speak in UTC time stamps. There are no time zones,
   there is only UTC. All "over the wire" dates and timestamps are
   UTC dates/timestamps.

   1. When returning a timestamp from the IFS database wrap it in
      `timestamp_api.local_to_utc`.
   2. When using a timestamp as a query parameter wrap it in
      `timestamp_api.utc_to_local`.

   (Note: in JVM land the easiest way to ensure this is the case is
   to set the JVM opt `-Duser.timezone=UTC`. An alternative if you
   want to present times to the user in their local time zone is to
   set the default after recording what the system default is:

   ```clojure
   (defn switch-to-utc []
    (let [tz (java.util.TimeZone/getDefault)
          utc (java.util.TimeZone/getTimeZone "UTC")]
     (java.util.TimeZone/setDefault utc)
     {:local-time-zone tz}))
   ```

   If you do use some form of the above rather than the JVM option
   be sure that you set the time zone to UTC before doing _anything_
   else (connecting to the database, etc.))

### Midnight Blues

Midnight is something of a special case. All _date_ values are
effectively timestamps as at midnight of that day. There is no
discernible difference. Between the _date_ and a timestamp of midnight
on the same day.

This makes things a little more complicated because per the Rules of
UTC Club a date is always fixed reference to a specific day. How can
we ensure we adhere to this rule if there is no means of
distinguishing a date from a midnight timestamp?

We treat all date/time values at midnight as being time zone
agnostic. They are always midnight, regardless of time zone.

Ask for a midnight value to be converted to UTC? It will still be
midnight.

Ask for a midnight UTC value to be converted to local time? It will
still be midnight.

This _shouldn't_ cause any real problems as the chances of a timestamp
value being recorded at _exactly_ midnight are fairly slim. But, it is
a trade-off you should be aware of.
 */
create or replace package timestamp_api is
  /* Returns the current time of the database in UTC */
  function now_utc return timestamp with time zone;

  -- Returns the UTC equivalent of time `d_` in time zone `tz_`
  -- (defaulting to the `dbtimezone`)
  function local_to_utc(
    d_ date,
    tz_ varchar2 default dbtimezone
  ) return timestamp with time zone;

  -- Returns the UTC equivalent of time `t_` in time zone `tz_`
  -- (defaulting to the `dbtimezone`)
  function local_to_utc(
    t_ timestamp,
    tz_ varchar2 default dbtimezone
  ) return timestamp with time zone;

  -- Returns the equivalent of UTC time `d_` in time zone `tz_`
  -- (defaulting to the `dbtimezone`)
  function utc_to_local(
    d_ date,
    tz_ varchar2 default dbtimezone
  ) return timestamp with time zone;

  -- Returns the equivalent of UTC time `t_` in time zone `tz_`
  -- (defaulting to the `dbtimezone`)
  function utc_to_local(
    t_ timestamp,
    tz_ varchar2 default dbtimezone
  ) return timestamp with time zone;

  -- Returns `t_` converted to UTC
  function to_utc(t_ timestamp with time zone) return timestamp with time zone;

  -- Returns `t_` in time zone `tz_` (defaulting to the `dbtimezone`)
  function to_local(
    t_ timestamp with time zone,
    tz_ varchar2 default dbtimezone
  ) return timestamp with time zone;

  /* Returns the current UNIX epoch offset of the database */
  function unix_epoch return number;

  /* Returns the UNIX epoch offset of the given time zoned timestamp */
  function to_epoch(t_ timestamp with time zone) return number;
end timestamp_api;
/
