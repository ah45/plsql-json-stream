create or replace package body iso8601_api is
  function date_to_char(d_ date) return varchar2 is
  begin
    return to_char(d_, date_fmt);
  end date_to_char;

  function time_to_char(
    ts_ date,
    us_ varchar2 default 'FALSE',
    with_tz_ varchar2 default 'FALSE'
  ) return varchar2 is
  begin
    return time_to_char(to_timestamp(ts_), us_, with_tz_);
  end time_to_char;

  function time_to_char(
    ts_ timestamp,
    us_ varchar2 default 'FALSE',
    with_tz_ varchar2 default 'FALSE'
  ) return varchar2 is
  begin
    return time_to_char(from_tz(ts_, sessiontimezone), us_, with_tz_);
  end time_to_char;

  function time_to_char(
    ts_ timestamp with time zone,
    us_ varchar2 default 'FALSE',
    with_tz_ varchar2 default 'FALSE'
  ) return varchar2 is
    tfmt_ varchar2(20) := time_fmt;
  begin
    if (us_ is not null and upper(us_) = 'TRUE') then
      tfmt_ := tfmt_ || us_fmt;
    end if;

    if (with_tz_ is not null and upper(with_tz_) = 'TRUE') then
      return to_char(ts_, tfmt_ || tz_fmt);
    else
      return to_char(ts_, tfmt_);
    end if;
  end time_to_char;

  function ts_to_char(ts_ date, us_ varchar2 default 'FALSE') return varchar2 is
  begin
    return ts_to_char(to_timestamp(ts_), us_);
  end ts_to_char;

  function ts_to_char(ts_ timestamp, us_ varchar2 default 'FALSE') return varchar2 is
    fmt_ varchar2(100) := date_fmt || ' ' || time_fmt;
  begin
    if (us_ is not null and upper(us_) = 'TRUE') then
      fmt_ := fmt_ || us_fmt;
    end if;

    return replace(to_char(ts_, fmt_), ' ', separator);
  end ts_to_char;

  function ts_to_char(
    ts_ timestamp with time zone,
    us_ varchar2 default 'FALSE'
  ) return varchar2 is
    fmt_ varchar2(100) := date_fmt || ' ' || time_fmt;
  begin
    if (us_ is not null and upper(us_) = 'TRUE') then
      fmt_ := fmt_ || us_fmt;
    end if;

    fmt_ := fmt_ || tz_fmt;

    return replace(to_char(ts_, fmt_), ' ', separator);
  end ts_to_char;

  function char_to_ts(
    s_ varchar2,
    default_timezone_ varchar2 default 'UTC'
  ) return timestamp with time zone is
  begin
    if (regexp_like(s_, ts_regexp)) then
      return to_timestamp_tz(
        replace(regexp_substr(s_, ts_regexp), separator, ' '),
        replace(date_fmt, 'i', 'y') || ' ' || time_fmt || us_fmt || tz_fmt
      );
    elsif (regexp_like(s_, date_regexp || separator || time_regexp)) then
      return from_tz(
        to_timestamp(
          replace(s_, separator, ' '),
          replace(date_fmt, 'i', 'y') || ' ' || time_fmt || us_fmt
        ),
        default_timezone_
      );
    elsif (regexp_like(s_, date_regexp)) then
      return from_tz(
        to_date(
          regexp_substr(s_, date_regexp),
          replace(date_fmt, 'i', 'y')
        ),
        default_timezone_
      );
    elsif (regexp_like(s_, time_regexp || tz_regexp)) then
      return to_timestamp_tz(
        regexp_substr(s_, time_regexp || tz_regexp),
        time_fmt || us_fmt || tz_fmt
      );
    elsif (regexp_like(s_, time_regexp)) then
      return from_tz(
        to_timestamp(regexp_substr(s_, time_regexp), time_fmt || us_fmt),
        default_timezone_
      );
    else
      return null;
    end if;
  end char_to_ts;
end iso8601_api;
/
