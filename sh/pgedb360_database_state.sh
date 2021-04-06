## Queries By Abel Macias and contributions.

title='Cluster'
sql_text='SELECT datname as "databases in this cluster" FROM pg_database WHERE NOT datistemplate AND datallowconn'
fc_exec_item

title='Version'
sql_text='select version()'
fc_exec_item

title='Uptime'
sql_text='select current_database(),pg_postmaster_start_time(),now()-pg_postmaster_start_time() as "Uptime"'
fc_exec_item

title='Database Info'
main_table='pg_settings'
sql_text=$(cat <<'END_HEREDOC'
select min(case name when 'huge_pages'            then setting end) as "Huge Pages",
       min(case name when 'shared_buffers'        then setting||' '||unit end) as "Shared Buffers",
       min(case name when 'work_mem'              then setting||' '||unit end) as "Work Memory",
       min(case name when 'wal_buffers'           then setting||' '||unit end) as "WAL Buffers",
       min(case name when 'max_wal_size'          then setting||' '||unit end) as "Max WAL Size",
       min(case name when 'archive_mode'          then setting end) as "Archive Mode",
       min(case name when 'hot_standby'           then setting end) as "Hot Standby",
       min(case name when 'password_encryption'   then setting END) as "Password Encryption",
       min(case name when 'prepared transactions' then setting end) as "Prepared Transactions"
  from (select name,setting,unit from pg_settings
         union
        select 'prepared transactions',count(1)::text,' ' from pg_prepared_xacts) p
END_HEREDOC
)
fc_exec_item

title='Connections'
main_table='pg_stat_activity'
sql_text=$(cat <<'END_HEREDOC'
select a.current_connections ,
       p.superuser_connections as "allowed superuser connections",
       round(100*a.current_connections/p.max_connections)::text||'%' as "connection saturation",
       a.oldest_connection,
       a.avg_connection_age,
       a.oldest_transaction
  from (select count(1) as current_connections,
               max(now()-backend_start) as oldest_connection,
               avg(now()-backend_start) as avg_connection_age,
               max(now()-xact_start) as oldest_transaction
          from pg_stat_activity) a,
       (select current_setting('max_connections')::integer as max_connections,
               current_setting('superuser_reserved_connections') as superuser_connections
       ) p
END_HEREDOC
)
fc_exec_item

title='Autovacuum'
main_table='pg_settings'
sql_text=$(cat <<'END_HEREDOC'
select autovacuum,autovacuum_max_workers,
       (case maintenance_work_mem when -1 then work_mem else maintenance_work_mem end)*autovacuum_max_workers autovacuum_max_memory_kb
  from (select min(case name when 'max_connections' then setting::integer end) as max_connections,
               min(case name when 'work_mem' then setting::integer end) as work_mem,
               min(case name when 'maintenance_work_mem' then setting::integer end) as maintenance_work_mem,
               min(case name when 'autovacuum_max_workers' then setting::integer end) as autovacuum_max_workers,
               min(case name when 'autovacuum' then setting end) as autovacuum
          from pg_settings
       ) p
END_HEREDOC
)
fc_exec_item

title='Stat Database'
main_table='pg_stat_database'
sql_text='select * from pg_stat_database'
fc_exec_item


