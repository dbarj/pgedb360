## Queries By Abel Macias and contributions.

sql_text_bkp=$(cat <<'END_HEREDOC'
select wait_event, state, count(1) as Num, 
       min(backend_start) as oldest_backend_start,
       min(xact_start) as oldest_xact_start,
       min(query_start) as oldest_query_start,
       min(state_change) as oldest_state_change
  from pg_stat_activity
 where datname=current_database()
   and state not in ('active','fastpath function call')
 group by wait_event, state
END_HEREDOC
)

title='Session - Snap 1'
main_table='pg_stat_activity'
sql_text=${sql_text_bkp}
fc_exec_item

sleep 10

title='Session - Snap 2'
main_table='pg_stat_activity'
sql_text=${sql_text_bkp}
fc_exec_item

sleep 10

title='Session - Snap 3'
main_table='pg_stat_activity'
sql_text=${sql_text_bkp}
fc_exec_item

sleep 10

title='Session - Snap 4'
main_table='pg_stat_activity'
sql_text=${sql_text_bkp}
fc_exec_item

sleep 10

title='Session - Snap 5'
main_table='pg_stat_activity'
sql_text=${sql_text_bkp}
fc_exec_item

sleep 10

title='Session - Snap 6'
main_table='pg_stat_activity'
sql_text=${sql_text_bkp}
fc_exec_item

sleep 10

title='Session - Snap 7'
main_table='pg_stat_activity'
sql_text=${sql_text_bkp}
fc_exec_item

sleep 10

title='Session - Snap 8'
main_table='pg_stat_activity'
sql_text=${sql_text_bkp}
fc_exec_item

#############################################
#############################################
#############################################

sql_text_bkp=$(cat <<'END_HEREDOC'
select state,count(1) as Num, 
       min(backend_start) as oldest_backend_start,
       min(xact_start) as oldest_xact_start,
       min(query_start) as oldest_query_start,
       min(state_change) as oldest_state_change
  from pg_stat_activity
 where datname=current_database()
 group by state
 order by state
END_HEREDOC
)

title='Session - Snap 1'
main_table='pg_stat_activity'
sql_text=${sql_text_bkp}
fc_exec_item

sleep 10

title='Session - Snap 2'
main_table='pg_stat_activity'
sql_text=${sql_text_bkp}
fc_exec_item

sleep 10

title='Session - Snap 3'
main_table='pg_stat_activity'
sql_text=${sql_text_bkp}
fc_exec_item

sleep 10

title='Session - Snap 4'
main_table='pg_stat_activity'
sql_text=${sql_text_bkp}
fc_exec_item

sleep 10

title='Session - Snap 5'
main_table='pg_stat_activity'
sql_text=${sql_text_bkp}
fc_exec_item

sleep 10

title='Session - Snap 6'
main_table='pg_stat_activity'
sql_text=${sql_text_bkp}
fc_exec_item

sleep 10

title='Session - Snap 7'
main_table='pg_stat_activity'
sql_text=${sql_text_bkp}
fc_exec_item

sleep 10

title='Session - Snap 8'
main_table='pg_stat_activity'
sql_text=${sql_text_bkp}
fc_exec_item

unset sql_text_bkp