## Queries By Abel Macias and contributions.

# PG 9.0 Hiperf book
title='Checkpoint efficiency'
sql_text=$(cat <<'END_HEREDOC'
SELECT current_setting('bgwriter_lru_maxpages')        as bgwriter_lru_maxpages,
       current_setting('bgwriter_lru_multiplier')      as bgwriter_lru_multiplier,
       current_setting('checkpoint_timeout')           as checkpoint_timeout,
       current_setting('checkpoint_completion_target') AS checkpoint_completion_target,
       current_setting('max_wal_size')                 as max_wal_size,
       current_setting('shared_buffers')               as shared_buffers
END_HEREDOC
)
fc_exec_item

title='Checkpoints'
sql_text=$(cat <<'END_HEREDOC'
SELECT 
(checkpoints_timed+checkpoints_req) AS "total checkpoints",
EXTRACT(EPOCH FROM (now() - stats_reset)) / (checkpoints_timed+checkpoints_req)/ 60 AS "minutes between checkpoints",
60*1000/cast(trim('ms' from current_setting('bgwriter_delay')) as integer)  AS "bgwriter writes per minute",
round(100 * checkpoints_timed  / (checkpoints_timed + checkpoints_req),2) ||' / '||               
round(100 * checkpoints_req    / (checkpoints_timed + checkpoints_req),2)                   AS "checkpoints timed/requested pct",
round(100 * buffers_checkpoint / (buffers_checkpoint + buffers_clean + buffers_backend),2) ||' / '|| 
round(100 * buffers_clean      / (buffers_checkpoint + buffers_clean + buffers_backend),2) ||' / '||   
round(100 * buffers_backend    / (buffers_checkpoint + buffers_clean + buffers_backend),2) AS "buffers clean by (checkpoint / bgwrt / backend) pct",
pg_size_pretty(buffers_checkpoint * block_size / (checkpoints_timed + checkpoints_req))    AS "average checkpoint write bytes",
pg_size_pretty(block_size * (buffers_checkpoint + buffers_clean + buffers_backend))        AS "total bytes written",
now()-stats_reset "time since stats reset",
stats_reset "stats reset timestamp"
FROM pg_stat_bgwriter,
     (select cast(current_setting('block_size') AS integer)  AS block_size,
             cast(trim('ms' from current_setting('bgwriter_delay')) as integer) AS bgwriter_delay
     ) AS p
END_HEREDOC
)
fc_exec_item