## Queries By Abel Macias and contributions.

## https://blog.dataegret.com/2017/10/deep-dive-into-postgres-stats.html

title='Locks'
sql_text=$(cat <<'END_HEREDOC'
WITH RECURSIVE l AS (
  SELECT pid, locktype, mode, granted,
 ROW(locktype,database,relation,page,tuple,virtualxid,transactionid,classid,objid,objsubid) obj
  FROM pg_locks
), pairs AS (
  SELECT w.pid waiter, l.pid locker, l.obj, l.mode
  FROM l w
  JOIN l ON l.obj IS NOT DISTINCT FROM w.obj AND l.locktype=w.locktype AND NOT l.pid=w.pid AND l.granted
  WHERE NOT w.granted
), tree AS (
  SELECT l.locker pid, l.locker root, NULL::record obj, NULL AS mode, 0 lvl, locker::text path, array_agg(l.locker) OVER () all_pids
  FROM ( SELECT DISTINCT locker FROM pairs l WHERE NOT EXISTS (SELECT 1 FROM pairs WHERE waiter=l.locker) ) l
  UNION ALL
  SELECT w.waiter pid, tree.root, w.obj, w.mode, tree.lvl+1, tree.path||'.'||w.waiter, all_pids || array_agg(w.waiter) OVER ()
  FROM tree JOIN pairs w ON tree.pid=w.locker AND NOT w.waiter = ANY ( all_pids )
)
SELECT (clock_timestamp() - a.xact_start)::interval(3) AS ts_age,
       replace(a.state, 'idle in transaction', 'idletx') state,
       (clock_timestamp() - state_change)::interval(3) AS change_age,
       a.datname,tree.pid,a.usename,a.client_addr,lvl,
       (SELECT count(*) FROM tree p WHERE p.path ~ ('^'||tree.path) AND NOT p.path=tree.path) blocked,
       repeat(' .', lvl)||' '||left(regexp_replace(query, '\s+', ' ', 'g'),100) query
FROM tree
JOIN pg_stat_activity a USING (pid)
ORDER BY path
END_HEREDOC
)
fc_exec_item

### https://severalnines.com/blog/why-postgresql-running-slow-tips-tricks-get-source
title='Blocker and blocked sessions and DML'
sql_text=$(cat <<'END_HEREDOC'
SELECT blocked_locks.pid     AS blocked_pid,
         blocked_activity.usename  AS blocked_user,
         blocking_locks.pid     AS blocking_pid,
         blocking_activity.usename AS blocking_user,
         blocked_activity.query    AS blocked_statement,
         blocking_activity.query   AS current_statement_in_blocking_process
   FROM  pg_catalog.pg_locks         blocked_locks
    JOIN pg_catalog.pg_stat_activity blocked_activity  ON blocked_activity.pid = blocked_locks.pid
    JOIN pg_catalog.pg_locks         blocking_locks 
        ON blocking_locks.locktype = blocked_locks.locktype
        AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
        AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
        AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
        AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
        AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
        AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
        AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
        AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
        AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
        AND blocking_locks.pid != blocked_locks.pid
    JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
   WHERE NOT blocked_locks.GRANTED
END_HEREDOC
)
fc_exec_item

### https://www.postgresql.org/docs/9.1/monitoring-stats.html
title='How many deadlocks and other conflict have happened'
sql_text=$(cat <<'END_HEREDOC'
select * from pg_stat_database_conflicts 
where datname = current_database()
END_HEREDOC
)
fc_exec_item
