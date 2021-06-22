-- This code must run the query on target database and return the output in CSV format.

-- get sql
GET &1.

-- header
SET HEA OFF FEED OFF TERM OFF PAGES 50000 VER OFF
SPO &2.
/
SPO OFF

SELECT prev_sql_id moat370_prev_sql_id,
       prev_child_number moat370_prev_child_number
FROM v$session
WHERE sid = SYS_CONTEXT('USERENV', 'SID')
/