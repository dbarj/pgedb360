## Queries By Abel Macias and contributions.

sql_text_bkp='select * from pg_stat_bgwriter'

title='BG Writer Perf - Snap 1'
sql_text=${sql_text_bkp}
fc_exec_item

sleep 10

title='BG Writer Perf - Snap 2'
sql_text=${sql_text_bkp}
fc_exec_item

sleep 10

title='BG Writer Perf - Snap 3'
sql_text=${sql_text_bkp}
fc_exec_item

sleep 10

title='BG Writer Perf - Snap 4'
sql_text=${sql_text_bkp}
fc_exec_item

sleep 10

title='BG Writer Perf - Snap 5'
sql_text=${sql_text_bkp}
fc_exec_item

unset sql_text_bkp