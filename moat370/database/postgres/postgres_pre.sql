\set hosts_count 1

create temp table cores(num_cores integer);
copy cores(num_cores) from program 'grep processor /proc/cpuinfo | wc -l';
select num_cores as avg_core_count from cores \gset
drop table cores;

\set avg_thread_count :avg_core_count

SELECT current_database() as database_name \gset

\set host_name :HOST

\set db_version :VERSION_NAME 