## Queries By Abel Macias and contributions.

title='Schema sizes'
main_table='pg_tables'
sql_text=$(cat <<'END_HEREDOC'
select schemaname,num_tables,
       pg_size_pretty(total_space) as "total space",
       round(100*total_space/sum(total_space) over (),2) "% of db",
       pg_size_pretty(table_space) as table_space,
       round(100*table_space/total_space,2) as "% of Schema",
       pg_size_pretty(total_space-table_space) as index_space,
       round(100*(total_space-table_space)/total_space,2) as "% of Schema",
       pg_size_pretty(sum(total_space) over () ) as total_space_db
  from ( select schemaname, count(*) num_tables,
                sum(pg_total_relation_size(schemaname||'.'||quote_ident(tablename))) as total_space,
                sum(pg_table_size(schemaname||'.'||quote_ident(tablename))) table_space
           from pg_tables
          GROUP BY schemaname
       ) t
 where total_space>0
 Order by total_space desc
END_HEREDOC
)
fc_exec_item

title='Top-25 tables by total_space'
main_table='pg_tables'
sql_text=$(cat <<'END_HEREDOC'
   select schemaname,tablename,
        pg_size_pretty(total_space_) total_space,
        pg_size_pretty(table_space_) table_space
   from (select schemaname,tablename,
                pg_total_relation_size(schemaname||'.'||quote_ident(tablename)) as total_space_,
                pg_table_size(schemaname||'.'||quote_ident(tablename)) table_space_
           from pg_tables
          order by total_space_ desc
         limit 25) d
END_HEREDOC
)
fc_exec_item

title='Top-25 tables by table_space'
main_table='pg_tables'
sql_text=$(cat <<'END_HEREDOC'
 select schemaname,tablename,
        pg_size_pretty(table_space_) table_space,
        pg_size_pretty(total_space_) total_space
    from (select schemaname,tablename,
                pg_total_relation_size(schemaname||'.'||quote_ident(tablename)) as total_space_,
                pg_table_size(schemaname||'.'||quote_ident(tablename)) table_space_
           from pg_tables
          order by table_space_ desc
         limit 25) d
END_HEREDOC
)
fc_exec_item

# https://paquier.xyz/manuals/postgresql/useful-queries/
title='Top-25 bloated tables'
main_table='pg_stat_user_tables'
sql_text=$(cat <<'END_HEREDOC'
SELECT 
    schemaname,relname as tablename,
    seq_scan,
    idx_scan,
    n_live_tup,
    n_dead_tup,
    round(n_dead_tup/(n_live_tup+0.0001),2) AS ratio,
    round(current_setting('autovacuum_vacuum_threshold')::integer
+ current_setting('autovacuum_vacuum_scale_factor')::numeric * n_live_tup) AS av_threshold,
    pg_size_pretty(pg_relation_size(relid)) size,
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
WHERE pg_relation_size(relid) > 1024 * 1024 AND
      n_live_tup > 0 
ORDER BY (case when pg_relation_size(relid)>2^30 then 1
               when pg_relation_size(relid)>2^25 then 2
               when pg_relation_size(relid)>2^20 then 3 
           else 4 end
          ),
         ratio DESC LIMIT 25
END_HEREDOC
)
fc_exec_item

title='Top-25 bloated indexes'
main_table='pg_index'
sql_text=$(cat <<'END_HEREDOC'
SELECT
nspname,t.relname as tablename,c.relname as indexname,
round(100 * pg_relation_size(indexrelid) / pg_relation_size(indrelid)) /100 AS index_ratio,
pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
pg_size_pretty(pg_relation_size(indrelid)) AS table_size
FROM pg_index I
LEFT JOIN pg_class C ON (C.oid = I.indexrelid)
LEFT JOIN pg_class t on (t.oid = I.indrelid)
LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)
WHERE nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast') 
  AND C.relkind='i' 
  AND pg_relation_size(indrelid) > 0
ORDER BY (case when pg_relation_size(indexrelid)>2^30 then 1
               when pg_relation_size(indexrelid)>2^25 then 2
               when pg_relation_size(indexrelid)>2^20 then 3 
           else 4 end
          ),
         index_ratio DESC LIMIT 25
END_HEREDOC
)
fc_exec_item

# https://www.dbrnd.com/2017/12/postgresql-script-to-find-the-used-space-by-toast-table/
title='Top-25 TOAST tables by space used'
main_table='pg_index'
sql_text=$(cat <<'END_HEREDOC'
SELECT 
     ss.relnamespace namespace,ss.relname as tablename,
     t.relnamespace toast_namespace,t.relname as toast_tablename, 
     pg_size_pretty(t.relpages*8192::numeric) toast_size,
     pg_size_pretty(pg_relation_size(ss.oid)) table_size
FROM pg_class t,
     (SELECT oid,relnamespace,relname,reltoastrelid
      FROM pg_class) AS ss
WHERE (t.oid = ss.reltoastrelid OR
       t.oid = (SELECT indexrelid
                  FROM pg_index
                 WHERE indrelid = ss.reltoastrelid))
  and relpages>1
ORDER BY relpages DESC limit 25
END_HEREDOC
)
fc_exec_item

title='Tables with dropped columns'
main_table='pg_attribute'
sql_text=$(cat <<'END_HEREDOC'
select a.attrelid::regclass,a.attname
 from pg_attribute a
-- where pg_catalog.pg_table_is_visible(c.oid)
where a.attisdropped
END_HEREDOC
)
fc_exec_item

# https://github.com/dataegret/pg-utils/blob/master/sql/table_write_activity.sql
title='Top-50 tables with the most changes in rows and HOT_rate'
main_table='pg_stat_user_tables'
sql_text=$(cat <<'END_HEREDOC'
SELECT
t.schemaname,t.relname as tablename,
pg_size_pretty(pg_relation_size(relid)),
coalesce(ts.spcname, (select spcname from pg_tablespace where oid=(select dattablespace from pg_database where datname=current_database()))) AS tblsp,
seq_scan,
idx_scan,
n_tup_ins,
n_tup_upd,
n_tup_del,
n_mod_since_analyze,
coalesce(n_tup_ins,0)+2*coalesce(n_tup_upd,0)-coalesce(n_tup_hot_upd,0)+coalesce(n_tup_del,0) as total_dmls,
(coalesce(n_tup_hot_upd,0)::float*100/(case when n_tup_upd>0 then n_tup_upd else 1 end)::float)::numeric(10,2) as "HOT rate",
(select v[1] FROM regexp_matches(reloptions::text,E'fillfactor=(\\d+)') as r(v) limit 1) as fillfactor
from pg_stat_user_tables t
JOIN pg_class c ON c.oid=relid
LEFT JOIN pg_tablespace ts ON ts.oid=c.reltablespace
WHERE
(coalesce(n_tup_ins,0)+coalesce(n_tup_upd,0)+coalesce(n_tup_del,0))>0
and t.schemaname not in ('pg_catalog', 'pg_global')
order by total_dmls desc limit 50
END_HEREDOC
)
fc_exec_item

# Book
# maybe useful to merge with the above query.
title='In need of vacuum as top-50 tables with the % of the most DML activity'
main_table='pg_stat_user_tables'
sql_text=$(cat <<'END_HEREDOC'
SELECT t.schemaname,t.relname as tablename,
       round(cast(n_tup_ins AS numeric) / (n_tup_ins + n_tup_upd + n_tup_del+0.0001),2) AS ins_pct,
       round(cast(n_tup_upd AS numeric) / (n_tup_ins + n_tup_upd + n_tup_del+0.0001),2) AS upd_pct,
       round(cast(n_tup_del AS numeric) / (n_tup_ins + n_tup_upd + n_tup_del+0.0001),2) AS del_pct, 
       now()-last_analyze as "since last analyze",now()-last_autoanalyze as "since last autoanalyze",
       reloptions
  from pg_stat_user_tables t
  JOIN pg_class c ON c.oid=relid  
 WHERE n_mod_since_analyze>0
   AND (date_part('days',least(now()-last_analyze,now()-last_autoanalyze))>7
        or (last_analyze is null and last_autoanalyze is null)
        or (select v[1] FROM regexp_matches(reloptions::text,E'autovacuum_enabled=false') as r(v) limit 1) IS NOT NULL
       )
 ORDER BY n_mod_since_analyze DESC
END_HEREDOC
)
fc_exec_item

title='Top 50 tables with columns with stats in need of validation'
main_table='pg_stats'
sql_text=$(cat <<'END_HEREDOC'
select s.schemaname,s.tablename,s.attname,s.n_distinct,n_mod_since_analyze
      ,last_vacuum,last_autovacuum
from pg_stats s
join pg_stat_user_tables t on (s.schemaname=t.schemaname and s.tablename=t.relname)
where n_mod_since_analyze>0 
  and (coalesce(n_distinct,0)<=0
   or coalesce(last_vacuum,last_autovacuum,now()-'30 days'::interval)<=now()-'30 days'::interval)
order by n_mod_since_analyze desc limit 50
END_HEREDOC
)
fc_exec_item

title='Tables with columns with stat target set'
main_table='pg_stats'
sql_text=$(cat <<'END_HEREDOC'
select n.nspname,c.relname as tablename,a.attname,
       (CASE attstattarget when 0 then 'Do not generate stats' else attstattarget::text END) Stat_Target
 from pg_attribute a JOIN pg_class c on c.oid=a.attrelid
 join pg_namespace n on n.oid=c.relnamespace
where attstattarget>-1
  and n.nspname not in ('pg_catalog','information_schema')
  and a.attnum>0
-- and pg_catalog.pg_table_is_visible(c.oid);
  and relkind='r'
END_HEREDOC
)
fc_exec_item

title='Top 50 indexes returning potentially the most dead tuples'
main_table='pg_stats'
sql_text=$(cat <<'END_HEREDOC'
select schemaname,relname,indexrelname,idx_scan,idx_tup_read,idx_tup_fetch,
       idx_tup_read-idx_tup_fetch as dead_tuple_idx_fetch,
       round(idx_tup_read/(idx_scan+0.0001),2) as avg_tuples,
       round(100 * idx_tup_fetch/(idx_tup_read+0.0001),2) as live_ratio
  from pg_stat_user_indexes
 order by dead_tuple_idx_fetch desc
 limit 50
END_HEREDOC
)
fc_exec_item

# https://paquier.xyz/manuals/postgresql/useful-queries/
# postgresqltuner.pl
title='Unused indexes'
main_table='pg_stat_user_indexes'
sql_text=$(cat <<'END_HEREDOC'
SELECT
    schemaname , relname AS tablename,
    indexrelname AS index,
    pg_size_pretty(pg_relation_size(i.indexrelid)) AS index_size,
    idx_scan as index_scans,
    indisvalid as is_valid,
    (select min('REF') from pg_constraint where conindid=i.indexrelid) as is_ref
FROM pg_stat_user_indexes ui
    JOIN pg_index i ON ui.indexrelid = i.indexrelid
WHERE (NOT indisunique 
       AND idx_scan < 50 
       AND pg_relation_size(relid) > 1024 * 1024)
   OR i.indisvalid=false
ORDER BY pg_relation_size(i.indexrelid) / nullif(idx_scan, 0) DESC NULLS FIRST,
    pg_relation_size(i.indexrelid) DESC
END_HEREDOC
)
fc_exec_item

# https://www.dbrnd.com/2015/09/postgresql-script-to-find-the-unused-and-duplicate-index/
title='Duplicate indexes'
main_table='pg_index'
sql_text=$(cat <<'END_HEREDOC'
SELECT
    indrelid::regclass AS TableName
    ,array_agg(indexrelid::regclass) AS Indexes
FROM pg_index 
GROUP BY 
    indrelid
    ,indkey 
HAVING COUNT(*) > 1
END_HEREDOC
)
fc_exec_item

# https://www.dbrnd.com/2017/04/postgresql-script-to-find-orphaned-sequence-not-owned-by-any-column-dba-can-remove-unwanted-sequence/
title='Orphaned sequences'
main_table='pg_class'
sql_text=$(cat <<'END_HEREDOC'
SELECT 
	ns.nspname AS SchemaName
	,c.relname AS SequenceName
FROM pg_class AS c
JOIN pg_namespace AS ns 
	ON c.relnamespace=ns.oid
WHERE c.relkind = 'S'
  AND NOT EXISTS (SELECT * FROM pg_depend WHERE objid=c.oid AND deptype='a')
ORDER BY c.relname
END_HEREDOC
)
fc_exec_item

# Some of the same output as \df 
# it may be possible to add functions pg_stat_get_function_calls,pg_stat_get_function_time,pg_stat_get_function_self_time (for some reason they are null)
title='Functions'
main_table='pg_class'


if [ ${pgedb360_server_version_num} -ge 110000 ]
then
  sql_text=$(cat <<'END_HEREDOC'
SELECT p.oid,n.nspname as "Schema", p.proname as "Name",
       pg_catalog.pg_stat_get_function_calls(p.oid) as "Calls",
 --      pg_catalog.pg_stat_get_function_time(p.oid)::text as "Time",
       pg_catalog.pg_stat_get_function_self_time(p.oid) as "Self Time",
       pg_catalog.pg_get_function_result(p.oid) as "Result data type", 
       CASE WHEN p.prokind THEN 'agg' WHEN p.proiswindow THEN 'window' WHEN p.prorettype = 'pg_catalog.trigger'::pg_catalog.regtype THEN 'trigger' ELSE 'normal' END as "Type",
       CASE WHEN p.prorows=1000 THEN 'Default' else p.prorows::text END as "Rows",
       CASE WHEN p.procost=100  THEN 'Default' else p.procost::text END as "Cost",
       pg_catalog.pg_get_function_arguments(p.oid) as "Argument data types"
  FROM pg_catalog.pg_proc p LEFT JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace 
WHERE n.nspname ~ '^(public)$' ORDER BY 1, 2, 4
END_HEREDOC
)
else
  sql_text=$(cat <<'END_HEREDOC'
SELECT p.oid,n.nspname as "Schema", p.proname as "Name",
       pg_catalog.pg_stat_get_function_calls(p.oid) as "Calls",
 --      pg_catalog.pg_stat_get_function_time(p.oid)::text as "Time",
       pg_catalog.pg_stat_get_function_self_time(p.oid) as "Self Time",
       pg_catalog.pg_get_function_result(p.oid) as "Result data type", 
       CASE WHEN p.proisagg THEN 'agg' WHEN p.proiswindow THEN 'window' WHEN p.prorettype = 'pg_catalog.trigger'::pg_catalog.regtype THEN 'trigger' ELSE 'normal' END as "Type",
       CASE WHEN p.prorows=1000 THEN 'Default' else p.prorows::text END as "Rows",
       CASE WHEN p.procost=100  THEN 'Default' else p.procost::text END as "Cost",
       pg_catalog.pg_get_function_arguments(p.oid) as "Argument data types"
  FROM pg_catalog.pg_proc p LEFT JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace 
WHERE n.nspname ~ '^(public)$' ORDER BY 1, 2, 4
END_HEREDOC
)
fi
fc_exec_item