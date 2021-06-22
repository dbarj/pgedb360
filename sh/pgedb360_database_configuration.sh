## Queries By Abel Macias and contributions.

title='All visible tables, views, sequences and foreign tables'
sql_text='\d'
output_type='text'
fc_exec_item

title='Lists tablespaces'
sql_text='\db+'
output_type='text'
fc_exec_item

# https://github.com/lesovsky/zabbix-extensions/issues/42
# select * from pg_ls_dir('pg_xlog');
# Abel Macias
# \! ls -l $PGDATA/pg_xlog
title='List of xlogs'
sql_text=$(cat <<'END_HEREDOC'
select d.xlog_dir||'/'||f.xlogfile xlogfile , pg_stat_file(d.xlog_dir||'/'||f.xlogfile) file_info
  from (select substr(sourcefile,1,position('/data/' in sourcefile)+5)||'pg_xlog' xlog_dir 
          from pg_file_settings 
          limit 1
       ) as d,
       (select pg_ls_dir('pg_xlog') as xlogfile) as f
  ORDER BY file_info
END_HEREDOC
)
fc_exec_item

# postgresqltuner.pl
title='Tablespaces'
main_table='pg_tablespace'
sql_text=$(cat <<'END_HEREDOC'
select spcname,pg_tablespace_location(oid) 
  from pg_tablespace 
 where pg_tablespace_location(oid) like current_setting('data_directory')||'/%'
END_HEREDOC
)
fc_exec_item

title='Lists installed extensions'
sql_text='\dx+'

title='Settings'
main_table='pg_settings'
sql_text=$(cat <<'END_HEREDOC'
select (case when boot_val is not null and setting<>boot_val then '*' END) not_default,
  name,unit,setting,boot_val,reset_val
  from pg_settings
 order by not_default,name
END_HEREDOC
)
fc_exec_item