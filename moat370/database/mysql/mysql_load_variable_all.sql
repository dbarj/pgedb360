select @query := `x`
from (
  select GROUP_CONCAT(concat('SELECT concat(''',VARIABLE_NAME,'='''''',@',VARIABLE_NAME,','''''''') as ''''') separator ' UNION ') x
  from   performance_schema.user_variables_by_thread
  where  THREAD_ID=@THREAD_ID
  and    VARIABLE_NAME<>'query'
) t;
PREPARE stmt1 FROM @query; 
tee %%file_name%%
EXECUTE stmt1; 
notee
DEALLOCATE PREPARE stmt1; 

-- tee %%file_name%%
-- SELECT concat('sum_cpu_count=''',@sum_cpu_count,'''') as '';
-- SELECT concat('avg_cpu_count=''',@avg_cpu_count,'''') as '';
-- SELECT concat('avg_core_count=''',@avg_core_count,'''') as '';
-- SELECT concat('avg_thread_count=''',@avg_thread_count,'''') as '';
-- SELECT concat('hosts_count=''',@hosts_count,'''') as '';
-- SELECT concat('moat370_spid=''',@moat370_spid,'''') as '';
-- SELECT concat('thread_id=''',@thread_id,'''') as '';
-- SELECT concat('database_name=''',@database_name,'''') as '';
-- SELECT concat('host_name=''',@host_name,'''') as '';
-- SELECT concat('db_version=''',@db_version,'''') as '';
-- notee