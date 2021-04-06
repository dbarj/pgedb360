-- get average number of CPUs
select @sum_cpu_count := `COUNT` from INFORMATION_SCHEMA.INNODB_METRICS where name = 'cpu_n';

-- get total number of CPUs
SET @avg_cpu_count := @sum_cpu_count;

-- get average number of Cores
SET @avg_core_count := @sum_cpu_count;

-- get average number of Threads
SET @avg_thread_count := @sum_cpu_count;

-- get number of Hosts
SET @hosts_count := 1;

-- get spid
SELECT @moat370_spid := `x` FROM (select CONNECTION_ID() x) t;

-- get threadid
SELECT @thread_id := `THREAD_ID` FROM performance_schema.threads where PROCESSLIST_ID = @moat370_spid;

-- get database name
SELECT @database_name := `x` FROM (select IFNULL(DATABASE(),'root') x) t;

-- get host name
SET @host_name := @@hostname;

-- get rdbms version
SELECT @db_version := `x` FROM (select VERSION() x) t;