## Queries By Abel Macias and contributions.

##############################
# fc_load_variable converts a database variable into a shellscript variable.
fc_load_variable pgedb360_pg_buffercache
##############################

title='Cache Hit Ratio'
main_table='pg_stat_database'
sql_text='select sum(blks_hit)*100/sum(blks_hit+blks_read) as "Global Cache Hit Ratio"
from pg_stat_database'
fc_exec_item

# PG 9.0 HiPerf book
title='Cache hit ratio per table'
main_table='pg_statio_user_tables'
sql_text=$(cat <<'END_HEREDOC'
with dat as
 (select schemaname,relname as tablename,
         coalesce(heap_blks_hit  ,0) heap_blks_hit,
         coalesce(heap_blks_read ,0) heap_blks_read,
         coalesce(toast_blks_hit ,0) toast_blks_hit,
         coalesce(toast_blks_read,0) toast_blks_read,
         coalesce(idx_blks_hit   ,0) idx_blks_hit,
         coalesce(idx_blks_read  ,0) idx_blks_read
   FROM pg_statio_user_tables        
)
SELECT 
       round(100*cast(heap_blks_hit  as numeric) / (heap_blks_hit + heap_blks_read+0.0001) ,2) AS hit_pct,
       round(100*cast(toast_blks_hit as numeric) / (toast_blks_hit+toast_blks_read+0.0001) ,2) AS toast_hit_pct,
       round(100*cast(idx_blks_hit   as numeric) / (idx_blks_hit  +  idx_blks_read+0.0001) ,2) AS idx_hit_pct,
       *
  FROM dat 
 WHERE heap_blks_hit>0 OR heap_blks_read>0 OR idx_blks_read>0
 ORDER BY (case when (heap_blks_read+toast_blks_read+idx_blks_read)>2^30 then 1
                when (heap_blks_read+toast_blks_read+idx_blks_read)>2^25 then 2 
                when (heap_blks_read+toast_blks_read+idx_blks_read)>2^20 then 3
           else 4 end
          ),hit_pct
END_HEREDOC
)
fc_exec_item

### PG 9.0 HiPerf book
### Accesing pg_buffercache may cause performance impact 
title='Relative to the buffer cache and its total size'
footer='How much data is being cached for each table'
main_table='pg_statio_user_tables'
sql_text=$(cat <<'END_HEREDOC'
SELECT
t.schemaname,c.relname as tablename,
pg_size_pretty(count(*) * 8192) as buffered,
round(100.0 * count(*) / 
(SELECT setting FROM pg_settings WHERE name='shared_buffers')::integer,2) AS "% of buffers",
round(100.0 * count(*) * 8192 / pg_table_size(c.oid),2) AS "% of table",
round(100.0*sum(case when isdirty then 1 else 0 end) / count(*),2) as "% dirty"
FROM pg_class c
INNER JOIN pg_buffercache b
ON b.relfilenode = c.relfilenode
INNER JOIN pg_database d
ON (b.reldatabase = d.oid AND d.datname = current_database())
INNER JOIN pg_statio_user_tables t
on (c.oid=t.relid)
GROUP BY t.schemaname,c.oid,c.relname
ORDER BY 3 DESC
LIMIT 25
END_HEREDOC
)
[ ${pgedb360_pg_buffercache} -gt 0 ] && fc_exec_item
footer=''

### PG 9.0 HiPerf book
### Decrease buffer cache if few blocks have high usage count. increase if most blocks have high usage count.
### Accesing pg_buffercache may cause performance impact

title='Histogram of objects pages usagecount'
main_table='pg_statio_user_tables'
sql_text=$(cat <<'END_HEREDOC'
SELECT t.schemaname, c.relname, count(*) AS buffers,usagecount
FROM pg_class c
INNER JOIN pg_buffercache b
ON b.relfilenode = c.relfilenode
INNER JOIN pg_database d
ON (b.reldatabase = d.oid AND d.datname = current_database())
INNER JOIN pg_statio_user_tables t
on (c.oid=t.relid)
GROUP BY t.schemaname,c.relname,usagecount
ORDER BY c.relname,usagecount
END_HEREDOC
)
[ ${pgedb360_pg_buffercache} -gt 0 ] && fc_exec_item