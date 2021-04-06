## Queries By Abel Macias and contributions.

###############
# SQL Related #
###############

if [ ${pgedb360_server_version_num} -ge 130000 ]
then
  pgedb360_time_col=total_exec_time
else
  pgedb360_time_col=total_time
fi

title='Top10 SQLs with the most acumulated elapsed time'
main_table='pg_stat_statements'
sql_text=$(cat <<END_HEREDOC
SELECT 
	pss.queryid
	,round(pss.${pgedb360_time_col} / 1000 / 60) AS \"TotalElaMinutes\"
  ,round((100*pss.${pgedb360_time_col}/ sum(pss.${pgedb360_time_col}) over ())::numeric,2 ) \"%TotalWorkload\"
  ,round((pss.${pgedb360_time_col}-pss.blk_read_time-pss.blk_write_time)/1000/60) as \"Total_Non_IO_time_Minutes\"
  ,round((100*(pss.${pgedb360_time_col}-pss.blk_read_time-pss.blk_write_time)/sum(pss.${pgedb360_time_col}) over ())::numeric,2) as \"%NonIOtime Of Wkld\"  	
  ,round((pss.blk_read_time+pss.blk_write_time) / 1000 / 60) AS \"Total_IO_Time_Minute\"
  ,round((100*(pss.blk_read_time+pss.blk_write_time)/pss.${pgedb360_time_col})::numeric,2) as \"%IOtime Of SQL\"
  ,round((100*(pss.blk_read_time+pss.blk_write_time)/(sum(pss.blk_read_time+pss.blk_write_time) over ()+0.00001))::numeric,2) as \"%IOtime Of WlkdIOTime\"
  ,round((100*(pss.blk_read_time+pss.blk_write_time)/sum(pss.${pgedb360_time_col}) over ())::numeric,2) as \"%IOtime Of TotalWkldtime\"
  ,round(min_time) as \"MinElapsed\",round(max_time) as \"MaxElapsed\"
  ,round(stddev_time::numeric,2) \"StdDev_time\"
  ,pss.calls as \"Execs\" 
  ,round(mean_time) as \"AvgElaTime\" ,round((pss.blk_read_time+blk_write_time)/calls) as \"AvrIOTime\"
  ,(pss.rows/pss.calls) AS \"RowsPerExec\"
  ,pss.query AS SQL	
FROM pg_stat_statements AS pss
INNER JOIN pg_database AS pd
	ON pss.dbid=pd.oid
WHERE pd.datname = current_database()
ORDER BY pss.${pgedb360_time_col} DESC 
LIMIT 10
END_HEREDOC
)
fc_exec_item

title='Top10 SQLs with the most acumulated IO time'
main_table='pg_stat_statements'
sql_text=$(cat <<END_HEREDOC
SELECT 
  pss.queryid
  ,round((pss.blk_read_time+pss.blk_write_time) / 1000 / 60) AS \"Total_IO_Time_Minute\"
  ,round((100*(pss.blk_read_time+pss.blk_write_time)/(sum(pss.blk_read_time+pss.blk_write_time) over ()+0.00001))::numeric,2) as \"%IOtime Of WlkdIOTime\"
  ,round((100*(pss.blk_read_time+pss.blk_write_time)/sum(pss.${pgedb360_time_col}) over ())::numeric,2) as \"%IOtime Of TotalWkldtime\"
  ,round((100*pss.${pgedb360_time_col}/ sum(pss.${pgedb360_time_col}) over ())::numeric,2 ) \"%TotalWorkload\"
  ,round((pss.${pgedb360_time_col}-pss.blk_read_time-pss.blk_write_time)/1000/60) as \"Total_Non_IO_time_Minutes\"
  ,round((100*(pss.${pgedb360_time_col}-pss.blk_read_time-pss.blk_write_time)/sum(pss.${pgedb360_time_col}) over ())::numeric,2) as \"%NonIOtime Of Wkld\"      
  ,round(pss.${pgedb360_time_col} / 1000 / 60) AS \"TotalElaMinutes\"
  ,round(mean_time) as \"AvgElaTime\" ,round((pss.blk_read_time+blk_write_time)/calls) as \"AvrIOTime\"  
  ,round((100*(pss.blk_read_time+pss.blk_write_time)/pss.${pgedb360_time_col})::numeric,2) as \"%IOtime Of SQL\"
  ,round(min_time) as \"MinElapsed\",round(max_time) as \"MaxElapsed\"
  ,round(stddev_time::numeric,2) \"StdDev_time\"
  ,pss.calls as \"Execs\"   
  ,(pss.rows/pss.calls) AS \"RowsPerExec\"
  ,pss.query AS SQL 
FROM pg_stat_statements AS pss
INNER JOIN pg_database AS pd
  ON pss.dbid=pd.oid
WHERE pd.datname = current_database()
ORDER BY (pss.blk_read_time+pss.blk_write_time) DESC 
LIMIT 10
END_HEREDOC
)
fc_exec_item


title='Top10 SQLs with the most Logical IO'
main_table='pg_stat_statements'
sql_text=$(cat <<END_HEREDOC
SELECT 
  pss.queryid
  ,pss.shared_blks_hit as \"TotalLIO\"
  ,round(100*pss.shared_blks_hit/(pss.shared_blks_hit+pss.shared_blks_read+0.00001),2) as \"HitRatio\"
  ,round(pss.${pgedb360_time_col} / 1000 / 60) AS \"TotalElaMinutes\"
  ,round((100*pss.${pgedb360_time_col}/ sum(pss.${pgedb360_time_col}) over ())::numeric,2 ) \"%TotalWorkload\"
  ,round((pss.${pgedb360_time_col}-pss.blk_read_time-pss.blk_write_time)/1000/60) as \"Total_Non_IO_time_Minutes\"
  ,round((100*(pss.${pgedb360_time_col}-pss.blk_read_time-pss.blk_write_time)/sum(pss.${pgedb360_time_col}) over ())::numeric,2) as \"%NonIOtime Of Wkld\"    
  ,round((pss.blk_read_time+pss.blk_write_time) / 1000 / 60) AS \"Total_IO_Time_Minute\"
  ,round((100*(pss.blk_read_time+pss.blk_write_time)/pss.${pgedb360_time_col})::numeric,2) as \"%IOtime Of SQL\"
  ,round((100*(pss.blk_read_time+pss.blk_write_time)/(sum(pss.blk_read_time+pss.blk_write_time) over ()+0.00001))::numeric,2) as \"%IOtime Of WlkdIOTime\"
  ,round((100*(pss.blk_read_time+pss.blk_write_time)/sum(pss.${pgedb360_time_col}) over ())::numeric,2) as \"%IOtime Of TotalWkldtime\"
  ,round(pss.min_time) as \"MinElapsed\",round(pss.max_time) as \"MaxElapsed\"
  ,round(pss.stddev_time::numeric,2) \"StdDev_time\"
  ,pss.calls as \"Execs\" 
  ,round(pss.mean_time) as \"AvgElaTime\" ,round((pss.blk_read_time+pss.blk_write_time)/calls) as \"AvrIOTime\"
  ,(pss.rows/pss.calls) AS \"RowsPerExec\"
  ,round(pss.shared_blks_hit/pss.calls) as \"AvgLIO\"
  ,round(pss.shared_blks_dirtied/pss.calls) as \"BlksDirtiedPerExec\"
  ,pss.query AS SQL 
FROM pg_stat_statements AS pss
INNER JOIN pg_database AS pd
  ON pss.dbid=pd.oid
WHERE pd.datname = current_database()
ORDER BY pss.shared_blks_hit DESC 
LIMIT 10
END_HEREDOC
)
fc_exec_item

title='Top10 SQLs with the most executions'
main_table='pg_stat_statements'
sql_text=$(cat <<END_HEREDOC
SELECT 
  pss.queryid
  ,pss.calls as \"Executions\" 
  ,round(100*pss.shared_blks_hit/(pss.shared_blks_hit+pss.shared_blks_read+0.00001),2) as \"HitRatio\"
  ,round(pss.${pgedb360_time_col} / 1000 / 60) AS \"TotalElaMinutes\"
  ,round((100*pss.${pgedb360_time_col}/ sum(pss.${pgedb360_time_col}) over ())::numeric,2 ) \"%TotalWorkload\"
  ,round((pss.${pgedb360_time_col}-pss.blk_read_time-pss.blk_write_time)/1000/60) as \"Total_Non_IO_time_Minutes\"
  ,round((100*(pss.${pgedb360_time_col}-pss.blk_read_time-pss.blk_write_time)/sum(pss.${pgedb360_time_col}) over ())::numeric,2) as \"%NonIOtime Of Wkld\"    
  ,round((pss.blk_read_time+pss.blk_write_time) / 1000 / 60) AS \"Total_IO_Time_Minute\"
  ,round((100*(pss.blk_read_time+pss.blk_write_time)/pss.${pgedb360_time_col})::numeric,2) as \"%IOtime Of SQL\"
  ,round((100*(pss.blk_read_time+pss.blk_write_time)/(sum(pss.blk_read_time+pss.blk_write_time) over ()+0.00001))::numeric,2) as \"%IOtime Of WlkdIOTime\"
  ,round((100*(pss.blk_read_time+pss.blk_write_time)/sum(pss.${pgedb360_time_col}) over ())::numeric,2) as \"%IOtime Of TotalWkldtime\"
  ,round(pss.min_time) as \"MinElapsed\",round(pss.max_time) as \"MaxElapsed\"
  ,round(pss.stddev_time::numeric,2) \"StdDev_time\"
  ,round(pss.mean_time) as \"AvgElaTime\" ,round((pss.blk_read_time+pss.blk_write_time)/calls) as \"AvrIOTime\"
  ,(pss.rows/pss.calls) AS \"RowsPerExec\"
  ,round(pss.shared_blks_hit/pss.calls) as \"AvgLIO\"
  ,round(pss.shared_blks_dirtied/pss.calls) as \"BlksDirtiedPerExec\"
  ,pss.query AS SQL 
FROM pg_stat_statements AS pss
INNER JOIN pg_database AS pd
  ON pss.dbid=pd.oid
WHERE pd.datname = current_database()
  AND pss.query not in ('BEGIN;','END;')
ORDER BY pss.calls DESC 
LIMIT 10
END_HEREDOC
)
fc_exec_item
