## Queries By Abel Macias and contributions.

title='Users with weak password'
sql_text=$(cat <<'END_HEREDOC'
select usename as "Users with weak password" from pg_shadow where passwd='md5'||md5(usename||usename)
END_HEREDOC
)
fc_exec_item

title='Users with weak password'
sql_text='\deu+'
output_type='text'
fc_exec_item
