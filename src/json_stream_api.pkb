create or replace package body json_stream_api is
  function escape_json_str(v_ varchar2) return varchar2 is
    es_ varchar2(32000);
    c_ char(1);

    special_chr_regex_ constant varchar2(200) := '['
      || '"'
      || '\\'
      || chr(8)
      || chr(9)
      || chr(10)
      || chr(12)
      || chr(13)
      || ']'
    ;
  begin
    if (v_ is null) then return ''; end if;
    if (not regexp_like(v_, special_chr_regex_, 'im')) then return v_; end if;

    for i_ in 1..length(v_) loop
      c_ := substr(v_, i_, 1);

      case c_
        when '\' then
          es_ := es_ || '\\';
        when '"' then
          es_ := es_ || '\"';
        when chr(8) then
          es_ := es_ || '\b';
        when chr(9) then
          es_ := es_ || '\t';
        when chr(10) then
          es_ := es_ || '\n';
        when chr(12) then
          es_ := es_ || '\f';
        when chr(13) then
          es_ := es_ || '\r';
        else
          es_ := es_ || c_;
      end case;
    end loop;

    return es_;
  end escape_json_str;


  function to_json_value(v_ varchar2) return varchar2 is
  begin
    return '"' || escape_json_str(v_) || '"';
  end to_json_value;

  function to_json_value(v_ number) return varchar2 is
  begin
    if (v_ is null) then return 'null'; end if;

    if (v_ < 1 and v_ > 0) then
      return '0' || v_;
    elsif (v_ > -1 and v_ < 0) then
      return '-0' || abs(v_);
    else
      return '' || v_;
    end if;
  end to_json_value;

  function to_json_value(v_ boolean) return varchar2 is
  begin
    if (v_ is null) then
      return 'null';
    elsif (v_) then
      return 'true';
    else
      return 'false ';
    end if;
  end to_json_value;

  function to_json_value(v_ timestamp with time zone) return varchar2 is
  begin
    if (v_ is null) then return 'null'; end if;
    return '"' || iso8601_api.ts_to_char(v_, 'TRUE') || '"';
  end to_json_value;

  function to_json_value(v_ timestamp) return varchar2 is
  begin
    return to_json_value(timestamp_api.local_to_utc(v_));
  end to_json_value;

  function to_json_value(v_ date) return varchar2 is
  begin
    return to_json_value(timestamp_api.local_to_utc(v_));
  end to_json_value;


  procedure write_to_clob(dst_ in out nocopy clob, v_ varchar2) is
  begin
    dbms_lob.writeappend(dst_, length(v_), v_);
  end write_to_clob;

  procedure write_to_clob(dst_ in out nocopy clob, v_ clob) is
    buf_len_ number := 15360;

    buf_ varchar2(15360) character set v_%charset;
    len_ number := buf_len_;
    pos_ number := 1;

    es_ varchar(32767);
  begin
    if (dbms_lob.getlength(v_) = 0) then return; end if;

    loop
      dbms_lob.read(v_, len_, pos_, buf_);

      pos_ := pos_ + len_;
      es_ := escape_json_str(buf_);

      dbms_lob.writeappend(dst_, length(es_), es_);

      if (len_ < buf_len_) then
        exit;
      end if;
    end loop;
  end write_to_clob;
end json_stream_api;
/
