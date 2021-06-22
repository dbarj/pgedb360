##############################
# fc_load_variable converts a database variable into a shellscript variable.
fc_load_variable pgedb360_pg_stat_statements
fc_load_variable pgedb360_pg_ash
fc_load_variable SERVER_VERSION_NUM pgedb360_server_version_num
##############################

# skip_if_no_pg_stat_statements will be empty ONLY if pg_stat_statements module exists
fc_set_value_var_decode skip_if_no_pg_stat_statements "${pgedb360_pg_stat_statements}" 0 '-' ''

# skip_if_no_pg_ash will be empty ONLY if pgsentinel module exists
fc_set_value_var_decode skip_if_no_pg_ash "${pgedb360_pg_ash}" 0 '-' ''
