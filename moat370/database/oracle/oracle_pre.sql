-- ENABLE ALL ROLES FOR USER
SET ROLE ALL;

-- NLS
ALTER SESSION SET NLS_NUMERIC_CHARACTERS=".,";
ALTER SESSION SET NLS_DATE_FORMAT='YYYY-MM-DD/HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT='YYYY-MM-DD/HH24:MI:SS.FF';
ALTER SESSION SET NLS_TIMESTAMP_TZ_FORMAT='YYYY-MM-DD/HH24:MI:SS.FF TZH:TZM';

-- get average number of CPUs
COL avg_cpu_count NEW_V avg_cpu_count FOR A6
SELECT TO_CHAR(ROUND(AVG(TO_NUMBER(value)),1)) avg_cpu_count FROM gv$system_parameter2 WHERE name='cpu_count';
COL avg_cpu_count clear

-- get total number of CPUs
COL sum_cpu_count NEW_V sum_cpu_count FOR A3
SELECT TO_CHAR(SUM(TO_NUMBER(value))) sum_cpu_count FROM gv$system_parameter2 WHERE name='cpu_count';
COL sum_cpu_count clear

-- get average number of Cores
COL avg_core_count NEW_V avg_core_count FOR A5
SELECT TO_CHAR(ROUND(AVG(TO_NUMBER(value)),1)) avg_core_count FROM gv$osstat WHERE stat_name='NUM_CPU_CORES';
COL avg_core_count clear

-- get average number of Threads
COL avg_thread_count NEW_V avg_thread_count FOR A6
SELECT TO_CHAR(ROUND(AVG(TO_NUMBER(value)),1)) avg_thread_count FROM gv$osstat WHERE stat_name='NUM_CPUS';
COL avg_thread_count clear

-- get number of Hosts
COL hosts_count NEW_V hosts_count FOR A2
SELECT TO_CHAR(COUNT(DISTINCT inst_id)) hosts_count FROM gv$osstat WHERE stat_name='NUM_CPU_CORES';
COL hosts_count clear

-- get udump directory path
COL moat370_udump_path NEW_V moat370_udump_path FOR A500
-- CHR(92)=\
SELECT value||DECODE(INSTR(value, '/'), 0, CHR(92), '/') moat370_udump_path FROM v$parameter2 WHERE name='user_dump_dest';
SELECT value||DECODE(INSTR(value, '/'), 0, CHR(92), '/') moat370_udump_path FROM v$diag_info WHERE name='Diag Trace';
COL moat370_udump_path clear

-- get background directory path
COL background_dump_dest NEW_V background_dump_dest
SELECT value background_dump_dest FROM v$parameter WHERE name = 'background_dump_dest';
COL background_dump_dest clear

-- get pid
COL moat370_spid NEW_V moat370_spid FOR A5
SELECT TO_CHAR(spid) moat370_spid FROM v$session s, v$process p
WHERE  s.sid=SYS_CONTEXT('USERENV', 'SID') AND p.addr=s.paddr;
COL moat370_spid clear

-- get database name (up to 10, stop before first '.', no special characters)
COL database_name NEW_V database_name
SELECT SYS_CONTEXT('USERENV', 'DB_NAME') database_name FROM DUAL;
COL database_name clear

-- get host name (up to 30, stop before first '.', no special characters)
COL host_name NEW_V host_name
SELECT SYS_CONTEXT('USERENV', 'SERVER_HOST') host_name FROM DUAL;
COL host_name clear

-- get rdbms version
COL db_version NEW_V db_version
SELECT version db_version FROM v$instance;
COL db_version clear

COL moat370_prev_sql_id NEW_V moat370_prev_sql_id NOPRI
COL moat370_prev_child_number NEW_V moat370_prev_child_number NOPRI