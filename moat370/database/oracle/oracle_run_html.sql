-- This code must run the query on target database and return the output in CSV format.

-- get sql
GET &1.

-- header
SET HEA ON FEED OFF TERM OFF PAGES 50000 VER OFF
SET MARK HTML ON SPOOL OFF
SPO &2.
/
SPO OFF
SET MARK HTML OFF

SELECT prev_sql_id moat370_prev_sql_id,
       prev_child_number moat370_prev_child_number
FROM v$session
WHERE sid = SYS_CONTEXT('USERENV', 'SID')
/