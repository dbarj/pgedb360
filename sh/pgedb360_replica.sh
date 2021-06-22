## Queries By Abel Macias and contributions.

title='Replica Settings'
main_table='pg_settings'
sql_text=$(cat <<'END_HEREDOC'
select (case when boot_val is not null and setting<>boot_val then '*' END) not_default,
  name,unit,setting,boot_val,reset_val
  from pg_settings
 where name in ('huge_pages','shared_buffers','work_mem','archive_mode',
 	           'hot_standby','max_replication_slots','prepared transactions',
 	           'track_commit_timestamp')
   or name like '%wal%'
 order by not_default,name
END_HEREDOC
)
fc_exec_item

title='Replication Status'
main_table='pg_replication_slots'
sql_text=$(cat <<'END_HEREDOC'
SELECT slot_name,
       pg_wal_lsn_diff(pg_current_wal_lsn(),restart_lsn) as restart_lag,
       pg_wal_lsn_diff(pg_current_wal_lsn(),confirmed_flush_lsn) as flush_lag
  FROM pg_replication_slots ORDER BY slot_name
END_HEREDOC
)
fc_exec_item

title='Replication Slots'
main_table='pg_replication_slots'
sql_text=$(cat <<'END_HEREDOC'
select *
 FROM pg_replication_slots ORDER BY slot_name
END_HEREDOC
)
fc_exec_item

title='Replication Origins'
main_table='pg_replication_origin'
sql_text='SELECT * FROM pg_replication_origin ORDER BY roname'
fc_exec_item

title='Replication Origin Status'
main_table='pg_replication_origin_status'
sql_text='SELECT * FROM pg_replication_origin_status order by external_id'
fc_exec_item

title='Objects with replica setting'
main_table='pg_class'
sql_text=$(cat <<'END_HEREDOC'
select * 
  from pg_class c 
 where (select v[1] FROM regexp_matches(reloptions::text,E'Replica') as r(v) limit 1) IS NOT NULL
 ORDER BY relname
END_HEREDOC
)
fc_exec_item

## https://blog.2ndquadrant.com/pg-phriday-terrific-throughput-tracking/
title='Replication Lags'
main_table='pg_stat_replication'
sql_text=$(cat <<'END_HEREDOC'
SELECT client_addr,
       pg_wal_lsn_diff(pg_current_wal_lsn(),sent_lsn) AS sent_lag,
       pg_wal_lsn_diff(pg_current_wal_lsn(),write_lsn) AS write_lag,
       pg_wal_lsn_diff(pg_current_wal_lsn(),flush_lsn) AS flush_lag,
       pg_wal_lsn_diff(pg_current_wal_lsn(),replay_lsn) AS replay_lag,
       *
  FROM pg_stat_replication order by pg_stat_replication desc
END_HEREDOC
)
fc_exec_item

title='Subscriptions'
main_table='pg_stat_subscription'
sql_text='select * from  pg_stat_subscription order by subname'
fc_exec_item

## https://github.com/lesovsky/zabbix-extensions/issues/42
## select * from pg_ls_dir('pg_xlog');
## Abel Macias
## \! ls -l $PGDATA/pg_xlog

title='List of xlogs'
main_table='pg_file_settings'
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
