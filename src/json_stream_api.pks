/*
LPE JSON stream based Generator
===============================

## Dependencies

* `timestamp_api`
* `iso8601_api`

*/
create or replace package json_stream_api is
  function escape_json_str(v_ varchar2) return varchar2;

  function to_json_value(v_ varchar2) return varchar2;
  function to_json_value(v_ number) return varchar2;
  function to_json_value(v_ boolean) return varchar2;
  function to_json_value(v_ timestamp with time zone) return varchar2;
  function to_json_value(v_ timestamp) return varchar2;
  function to_json_value(v_ date) return varchar2;

  procedure write_to_clob(dst_ in out nocopy clob, v_ varchar2);
  procedure write_to_clob(dst_ in out nocopy clob, v_ clob);
end json_stream_api;
/
