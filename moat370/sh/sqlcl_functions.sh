#!/bin/bash
#************************************************************************
#
#   Copyright 2021  Rodrigo Jorge <http://www.dbarj.com.br/>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#************************************************************************

########################
# Mandatory Functions: #
########################

# fc_db_startup_connection
# fc_db_end_connection
# fc_db_check_connection
# fc_db_begin_code
# fc_db_end_code
# fc_db_run_file
# fc_db_define_module
# fc_db_reset_options
# fc_db_pre_section_call
# fc_db_create_csv
# fc_db_create_raw
# fc_db_table_description
# fc_db_check_file_sql_error
# fc_db_enable_trace
# fc_db_pre_exec_call
# fc_db_sql_transform

########################

# printf %s\\n "$-"
bin_check_exit sql
bin_check_exit mkfifo

# https://serverfault.com/questions/188936/writing-to-stdin-of-background-process
# https://stackoverflow.com/questions/5422767/redirecting-input-of-application-java-but-still-allowing-stdin-in-bash
fc_db_startup_connection ()
{
  fc_def_output_file v_database_fifo_file 'database.fifo.sql'
  [ -p "${v_database_fifo_file}" ] && rm -f "${v_database_fifo_file}"
  mkfifo "${v_database_fifo_file}"
  # exec 3<>"${v_database_fifo_file}"
  fc_def_output_file v_database_out_file 'database_output.log'
  fc_disable_all_sets
  #cat <&3 | sql -L ${moat370_sw_db_conn_params} > "${v_database_out_file}" &
  local old_tty_settings=`stty -g`
  tail -f "${v_database_fifo_file}" | sql /nolog > "${v_database_out_file}" &
  v_db_client_pid=$!
  sleep 10 # sqlcl will run the first entry in pipe and leave if I remove this.
  #stty sane 
  stty "$old_tty_settings" # sqlcl destroy all the stty default options. stty sane will restore it.
  fc_enable_all_sets
}

fc_db_end_connection ()
{
  fc_run_query "EXIT;"
  [ -p "${v_database_fifo_file}" ] && rm -f "${v_database_fifo_file}"
  fc_seq_output_file v_database_out_file
  fc_zip_file "${moat370_zip_filename}" "${v_database_out_file}"
  db_connection_kill
}

fc_db_check_connection ()
{
  local v_loop_limit v_sleep_time v_total_sleep
  v_loop_limit=5
  v_sleep_time=1
  v_total_sleep=0

  fc_run_query "conn ${moat370_sw_db_conn_params}"
  fc_run_query "SELECT 'I_AM_CONNECTED_' || COUNT(*) FROM DUAL;"

  set +x

  while :
  do
    if grep -q 'I_AM_CONNECTED_1' "${v_database_out_file}"
    then
      break
    fi
    sleep ${v_sleep_time}
    v_total_sleep=$(do_calc "v_total_sleep+1")
    if [ ${v_total_sleep} -gt ${v_loop_limit} ]
    then
      cat "${v_database_out_file}"
      exit_error "Unable to connect on database.. time limit exceeded."
    fi
  done

  fc_enable_set_x

}

fc_db_begin_code ()
{
  fc_db_run_file "${moat370_fdr}"/database/oracle/oracle_version.sql
  fc_db_run_file "${moat370_fdr}"/database/oracle/oracle_pre.sql
  fc_load_variable ALL
  fc_load_variable _SQLPLUS_RELEASE v_database_release
}

fc_db_end_code ()
{
  fc_db_run_file "${moat370_fdr}"/database/oracle/oracle_post.sql
}

fc_db_run_file ()
{
  fc_run_query "@$1"
  fc_check_executed
}

fc_db_define_module ()
{
  fc_run_query "EXEC DBMS_APPLICATION_INFO.SET_MODULE('${moat370_prefix}','${section_id}');"
}

fc_db_reset_options ()
{
  sql_text_cdb=''
  fc_db_run_file "${moat370_fdr}"/database/oracle/oracle_reset.sql
}

fc_db_pre_section_call ()
{
  fc_oracle_tkprof
}

fc_db_create_csv ()
{
  local v_in_file="$1"
  local v_out_csv="$2"

  # ATTENTION
  # sqlcl_run_csv.sql is not working due to line breaks within CSV line. << TODO: FIX THIS

  fc_def_output_file v_out_html 'fc_db_create_html.out'
  rm -f "${v_out_html}"

  fc_run_query "@${moat370_fdr}/database/oracle/sqlcl_run_html.sql ${v_in_file} ${v_out_html}"
  fc_check_executed
  fc_convert_html_to_csv "${v_out_html}" "${v_out_csv}"
  rm -f "${v_out_html}"
  unset v_out_html

  # Trim trailing blank lines
  $cmd_sed -e ':a' -e '/./,$!d;/^\n*$/{$d;N;};/\n$/ba' "${v_out_csv}" > "${v_out_csv}".tmp
  mv "${v_out_csv}".tmp "${v_out_csv}"

  fc_load_variable MOAT370_PREV_SQL_ID moat370_prev_sql_id
  fc_load_variable MOAT370_PREV_CHILD_NUMBER moat370_prev_child_number

  fc_db_reset_options
}

fc_db_create_raw ()
{
  local v_in_file="$1"
  local v_out_file="$2"

  fc_def_output_file v_out_raw 'fc_db_create_raw.out'
  rm -f "${v_out_raw}"

  fc_run_query "@${moat370_fdr}/database/oracle/oracle_run_raw.sql ${v_in_file} ${v_out_raw}"
  fc_check_executed
  $cmd_sed -e ':a' -e '/./,$!d;/^\n*$/{$d;N;};/\n$/ba' "${v_out_raw}" > "${v_out_file}"

  rm -f "${v_out_raw}"
  unset v_out_raw

  fc_load_variable MOAT370_PREV_SQL_ID moat370_prev_sql_id
  fc_load_variable MOAT370_PREV_CHILD_NUMBER moat370_prev_child_number

  fc_db_reset_options
}

fc_db_table_description ()
{
  local v_output_file
  v_output_file="$1"
  fc_run_query "@${moat370_fdr}/database/oracle/oracle_table_desc.sql ${v_output_file} ${moat370_sw_desc_linesize} ${main_table}"
  fc_check_executed
}

fc_db_check_file_sql_error ()
{
  ## This code will check if file has an error.

  local v_in_file="$1"
  if grep -q '^ORA-' ${v_in_file} && grep -q '^ERROR' ${v_in_file}
  then
    return 1
  else
    return 0
  fi
}

fc_db_enable_trace ()
{
  fc_run_query "ALTER SESSION SET MAX_DUMP_FILE_SIZE='1G';"
  fc_run_query "ALTER SESSION SET TRACEFILE_IDENTIFIER=\"${moat370_tracefile_identifier}\";"
  fc_run_query "ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL ${sql_trace_level}';"
}

fc_db_pre_exec_call ()
{
  ## Check if we will use sql_text or sql_text_cdb
  if [ -n "${sql_text_cdb}" -a "${is_cdb}" = 'Y' ]
  then
    sql_text=${sql_text_cdb}
  fi

  sql_with_clause=$(trim_var "${sql_with_clause}")
  sql_with_clause=$($cmd_sed -e :a -e '/./,$!d;/^\n*$/{$d;N;};/\n$/ba' <<< "${sql_with_clause}")
}

fc_db_sql_transform ()
{
  local v_in_query="$1"
  local v_extra_with_clause=''
  [ -n "${sql_with_clause}" ] && v_extra_with_clause="$(printf '%s\n' "${sql_with_clause}")"
  printf '%sSELECT TO_CHAR(ROWNUM) row_num, v0.* FROM /* %s */ (\n%s\n) v0 WHERE ROWNUM <= %s' "${v_extra_with_clause}" "${section_id}.${report_sequence}" "${v_in_query}" "${max_rows}"
}

################################
###### INTERNAL FUNCTIONS ######
################################

fc_run_query ()
{
  echo "${1}" > "${v_database_fifo_file}"
}

fc_check_executed ()
{
  # Optional parameter for how long (seconds) will wait.
  set +u
  local v_wait_limit="$1"
  fc_enable_set_u

  # Check if database FIFO file reached the end.
  fc_def_output_file v_fc_db_run_file_output 'run_file.out'
  rm -f "${v_fc_db_run_file_output}"

  fc_run_query "SPOOL ${v_fc_db_run_file_output}"
  fc_run_query "PRO FINISHED"
  fc_run_query "SPOOL OFF"
  fc_wait_string "${v_fc_db_run_file_output}" FINISHED ${v_wait_limit}

  rm -f "${v_fc_db_run_file_output}"
}

fc_load_variable ()
{
  # This code will convert DEFINE variables into SHELL variables.
  local v_load_variable_file v_load_variable_name v_output
  v_load_variable_name="$1"

  set +u
  v_load_target_name="$2"
  fc_enable_set_u

  fc_def_output_file v_load_variable_file 'fc_load_variable.out'
  rm -f "${v_load_variable_file}"

  if [ "${v_load_variable_name}" != 'ALL' ]
  then
    fc_run_query "@${moat370_fdr}/database/oracle/oracle_load_variable.sql ${v_load_variable_file} ${v_load_variable_name}"
    fc_check_executed

    v_output=$(sed '/^DEFINE/!d' "${v_load_variable_file}")

    if grep -q 'SP2-0135' "${v_load_variable_file}"
    then
      cat "${v_load_variable_file}"
      exit_error "Undefined variable ${v_load_variable_name}."
    fi

    v_value_var=$(sed 's/^[^"]*"\(.*\)"[^"]*$/\1/' <<< "${v_output}")

    if [ -z "${v_load_target_name}" ]
    then
      v_def_var=$(sed 's/^DEFINE *\([^ ]*\) .*/\1/' <<< "${v_output}")
      v_def_var=$(lower_var "${v_def_var}")
    else
      v_def_var="${v_load_target_name}"
    fi

    eval ${v_def_var}=\${v_value_var}
  else
    fc_run_query "@${moat370_fdr}/database/oracle/oracle_load_variable.sql ${v_load_variable_file} ''"
    fc_check_executed

    v_output=$(sed '/^DEFINE/!d' "${v_load_variable_file}")

    while read line || [ -n "$line" ]
    do
      v_def_var=$(sed 's/^DEFINE *\([^ ]*\) .*/\1/' <<< "${line}")
      v_def_var=$(lower_var "${v_def_var}")

      v_value_var=$(sed 's/^[^=]*= *//; s/ *([^(]*$//; s/^"//; s/"$//' <<< "${line}")
      
      if [ "${v_def_var}" = "1" ] || [ "${v_def_var}" = "2" ] || [ "$(substr_var ${v_def_var} 1 1)" = "_" ]
      then
        continue
      fi
      eval ${v_def_var}=\${v_value_var}
    done <<< "${v_output}"
  fi

  rm -f "${v_load_variable_file}"

}

fc_oracle_tkprof ()
{
  if [ -z "${skip_trace}" ]
  then
    v_trc_files="${moat370_udump_path}*ora_${moat370_spid}_${moat370_tracefile_identifier}.trc"
    ## tkprof for trace from execution of tool in case someone reports slow performance in tool
    if ls ${v_trc_files} 1> /dev/null 2>&1
    then
      ls -lat ${v_trc_files} >> "${moat370_log3}"
      tkprof ${v_trc_files} "${moat370_trace}_sort.txt" sort=prsela exeela fchela >> "${moat370_log3}"
      fc_zip_file "${moat370_zip_filename}" "${moat370_trace}_sort.txt"
    fi
  fi
}

fc_convert_html_to_csv ()
{
  # https://www.computerhope.com/unix/used.htm
  # https://unix.stackexchange.com/questions/335497/get-text-between-start-pattern-and-end-pattern-based-on-pattern-between-start-an
  # https://unix.stackexchange.com/questions/26284/how-can-i-use-sed-to-replace-a-multi-line-string
  # https://stackoverflow.com/questions/6588113/remove-new-line-if-next-line-does-not-begin-with-a-number/6616184
  # https://www.unix.com/shell-programming-and-scripting/267032-sed-remove-newline-chars-based-pattern-mis-match.html

  local v_in_file="$1"
  local v_out_file="$2"

  # Spool file
  cat "${v_in_file}" | \
  # Remove all lines before <table> entry
  $cmd_sed '1,/^<div>/d' | \
  # Remove all lines after </table> entry
  $cmd_sed '/<\/table>/q' | \
  # Add a New line after <tr>
  $cmd_sed $'s:<tr>:\\\n:g' | \
  # Trim line, replace double the double quotes and remove empty lines. 
  $cmd_sed 's/^[[:space:]]*//g; s/[[:space:]]*$//g; s/&nbsp;//; s/"/""/g; /^$/d' | \
  # Replace new lines with form feed character
  tr '\n' '\f' | \
  # Remove linebreaks from csv fields
  $cmd_sed $'s/\f\([^<]\)/ \\1/g' | \
  # Replace HTML columns end/start with '","'
  $cmd_sed $'s:</th>\f<th[^>]*>:",":g ; s:</td>\f<td[^>]*>:",":g' | \
  # Replace HTML line end/start with '"'
  $cmd_sed $'s:<th[^>]*>:":g ; s:</th>:":g ; s:<td[^>]*>:":g ; s:</td>:":g' | \
  # Replace form feed character back to new lines
  tr '\f' '\n' | \
  # Remove any other HTML line and empty lines.
  $cmd_sed '/^</d' > "${v_out_file}"
}