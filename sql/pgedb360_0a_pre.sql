\pset footer off
\timing on

-- Check if pg_buffercache module is enabled.
SELECT count(1) as pgedb360_pg_buffercache
from   pg_extension
where  extname='pg_buffercache'
\gset

-- Check if pg_stat_statements module is enabled.
SELECT count(1) as pgedb360_pg_stat_statements
from   pg_extension
where  extname='pg_stat_statements'
\gset

