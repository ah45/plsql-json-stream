/*
LPE ISO8601 API
===============

A date/time/timestamp <-> string conversion library conforming to the ISO8601
standard.

Resources:

* http://www.iso.org/iso/home/standards/iso8601.htm
* http://en.wikipedia.org/wiki/ISO_8601

## Usage

To convert a time value to a ISO8601 string:

    iso8601_api.ts_to_char(systimestamp);
    ;=> '2015-01-20T08:20:45+01:00'

To convert a ISO8601 format string to a timestamp value:

    iso8601_api.char_to_ts('2015-01-20T08:20:45+01:00');
    ;=> 20-JAN-15 08.20.45.00000 +01:00

Note that if the date/time value supplied to `ts_to_char` doesn't
include the time zone then no time zone will be written to the string
and converting back to a timestamp will yield a UTC value unless you
specify a time zone to use:

   iso8601_api.ts_to_char(sysdate);
   ;=> '2015-01-20T08:20:45'

   iso8601_api.char_to_ts('2015-01-20T08:20:45');
   ;=> 20-JAN-15 08.20.45.00000 UTC

   iso8601_api.char_to_ts('2015-01-20T08:20:45', 'Europe/London');
   ;=> 20-JAN-15 08.20.45.00000 EUROPE/LONDON

   iso8601_api.char_to_ts('2015-01-20T08:20:45', '+05:00');
   ;=> 20-JAN-15 08.20.45.00000 +05:00

Partial conversions are also possible:

    iso8601_api.date_to_char(sysdate); -- 2015-01-20
    iso8601_api.time_to_char(sysdate); -- 08:20:45
    -- optionally add the timezone offset:
    iso8601_api.time_to_char(sysdate, 'TRUE'); -- 08:20:45+00:00

In both cases these functions return the corresponding _portion_ of the
ISO8601 string rather than the full timestamp.
 */
create or replace package iso8601_api is
  date_fmt varchar2(20) := 'iyyy-mm-dd';
  time_fmt varchar2(20) := 'hh24:mi:ss';
  us_fmt   varchar2(7)  := '.ff6';
  tz_fmt   varchar2(20) := 'tzh:tzm';
  separator varchar2(1) := 'T';

  date_regexp varchar2(20) := '\d{4}\-\d{2}\-\d{2}';
  time_regexp varchar2(40) := '\d{2}:\d{2}:\d{2}(\.\d{1,6})?';
  tz_regexp   varchar2(20) := '[\-\+]\d{2}:\d{2}';
  ts_regexp   varchar2(100) := date_regexp || separator || time_regexp || tz_regexp;

  /* Convert a date/time value to an ISO8601 date string
   *
   *     date_to_char(to_date('01-20-15', 'mm-dd-yy')); -- 2015-01-20
   */
  function date_to_char(d_ date) return varchar2;

  /* Convert a date/time value to an ISO8601 time string optionally
   * including the microseconds and/or with the timezone appended.
   *
   *     time_to_char(systimestamp);                  -- 08:25:40
   *     time_to_char(systimestamp, 'TRUE');          -- 08:25:40.324567
   *     time_to_char(systimestamp, 'TRUE', 'TRUE');  -- 08:25:40.324567+00:00
   *     time_to_char(systimestamp, 'FALSE', 'TRUE'); -- 08:25:40+00:00
   *
   *     time_to_char(to_timestamp('08:25:40', 'hh24:mi:ss'));
   *     -- 08:25:40
   *     time_to_char(
   *       from_tz(to_timestamp('08:25:40', 'hh24:mi:ss'), 'US/Eastern'),
   *       'TRUE'
   *     );
   *     -- 08:25:40-05:00
   */
  function time_to_char(
    ts_ date,
    us_ varchar2 default 'FALSE',
    with_tz_ varchar2 default 'FALSE'
  ) return varchar2;

  function time_to_char(
    ts_ timestamp,
    us_ varchar2 default 'FALSE',
    with_tz_ varchar2 default 'FALSE'
  ) return varchar2;

  function time_to_char(
    ts_ timestamp with time zone,
    us_ varchar2 default 'FALSE',
    with_tz_ varchar2 default 'FALSE'
  ) return varchar2;

  /* Convert a date/time value to an ISO8601 timestamp string optionally
   * including the microseconds.
   *
   *     ts_to_char(sysdate);
   *     -- 2015-01-20T08:20:45+00:00
   *     ts_to_char(systimestamp, 'TRUE');
   *     -- 2015-01-20T08:20:45.334568+00:00
   *     ts_to_char(
   *       from_tz(
   *         to_timestamp('02-22-14 12:10:50', 'mm-dd-yy hh24:mi:ss'),
   *         'Asia/Dacca'
   *       )
   *     );
   *     -- 2014-02-22T12:10:50+06:00
   */
  function ts_to_char(ts_ date, us_ varchar2 default 'FALSE') return varchar2;
  function ts_to_char(ts_ timestamp, us_ varchar2 default 'FALSE') return varchar2;
  function ts_to_char(
    ts_ timestamp with time zone,
    us_ varchar2 default 'FALSE'
  ) return varchar2;

  /* Convert an ISO8601 formatted date/time/timestamp string to
   * a timestamp.
   *
   * If the string contains no time zone information then
   * `default_timezone_` will be used as its time zone (defaulting to
   * UTC.)
   */
  function char_to_ts(
    s_ varchar2,
    default_timezone_ varchar2 default 'UTC'
  ) return timestamp with time zone;
end iso8601_api;
/
