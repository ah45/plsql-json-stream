create or replace package body timestamp_api is
  unix_epoch_ constant date := to_date('1970-01-01', 'yyyy-mm-dd');

  ----------------------------------------------------------------------
  -- Private Methods
  ----------------------------------------------------------------------
  function midnight(t_ timestamp with time zone) return boolean is
  begin
    return trunc(t_) = cast(t_ as timestamp);
  end midnight;


  ----------------------------------------------------------------------
  -- Public Methods
  ----------------------------------------------------------------------
  function now_utc return timestamp with time zone is
  begin
    return local_to_utc(cast(systimestamp as timestamp));
  end now_utc;


  function local_to_utc(
    d_ date,
    tz_ varchar2 default dbtimezone
  ) return timestamp with time zone is
  begin
    return local_to_utc(to_timestamp(d_), tz_);
  end local_to_utc;


  function local_to_utc(
    t_ timestamp,
    tz_ varchar2 default dbtimezone
  ) return timestamp with time zone is
  begin
    return to_utc(from_tz(t_, tz_));
  end local_to_utc;


  function utc_to_local(
    d_ date,
    tz_ varchar2 default dbtimezone
  ) return timestamp with time zone is
  begin
    return utc_to_local(to_timestamp(d_), tz_);
  end utc_to_local;


  function utc_to_local(
    t_ timestamp,
    tz_ varchar2 default dbtimezone
  ) return timestamp with time zone is
  begin
    return to_local(from_tz(t_, 'UTC'), tz_);
  end utc_to_local;


  function to_utc(t_ timestamp with time zone) return timestamp with time zone is
  begin
    if (midnight(t_)) then
      return from_tz(cast(t_ as timestamp), 'UTC');
    else
      return t_ at time zone 'UTC';
    end if;
  end to_utc;


  function to_local(
    t_ timestamp with time zone,
    tz_ varchar2 default dbtimezone
  ) return timestamp with time zone is
  begin
    if (midnight(t_)) then
      return from_tz(cast(t_ as timestamp), tz_);
    else
      return t_ at time zone tz_;
    end if;
  end to_local;


  function unix_epoch return number is
  begin
    return to_epoch(now_utc);
  end unix_epoch;


  function to_epoch(t_ timestamp with time zone) return number is
  begin
    return (
      (cast(to_utc(t_) as date) - unix_epoch_)
      * 86400
      * 1000
      + to_number(to_char(t_, 'FF3'))
    );
  end to_epoch;
end timestamp_api;
/
