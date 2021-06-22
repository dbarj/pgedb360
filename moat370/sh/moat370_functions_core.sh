#!/bin/bash
#************************************************************************
#
#   Copyright 2021  Rodrigo Jorge <http://www.dbarj.com.br/>
#
#   Licensed under the Apache License, Version 2.0 (the "License"
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES -o CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#************************************************************************

echo_time ()
{
  # Print appending the time.
  echo "$(get_date_time): $1"
}

echo_error ()
{
  # Print message to STDERR
  (>&2 echo_time "ERROR: $1")
}

db_connection_kill ()
{
  # Kill DB Connection if stabilished.
  if db_connection_check
  then
    kill ${v_db_client_pid}
  fi
}

db_connection_sigint ()
{
  # Send SIGINT to DB Connection if stabilished.
  if db_connection_check
  then
    kill -SIGINT ${v_db_client_pid}
  fi
}

db_connection_check ()
{
  # Kill DB Connection if stabilished.
  fc_def_empty_var v_db_client_pid
  if [ -n "${v_db_client_pid}" ]
  then
    if kill -0 ${v_db_client_pid} > /dev/null 2>&1
    then
      return 0
    else
      return 1
    fi
  else
    return 1
  fi
}

save_bash_variables ()
{
  # Save all script variables for easier debugging.
  fc_def_empty_var moat370_sw_output_fdr
  if [ -n "${moat370_sw_output_fdr}" ] && \
     [ -w "${moat370_sw_output_fdr}" ] && \
     ${moat370_code_set_x}
  then
    fc_def_output_file last_run_vars 'last_run_vars.env'
    ( set -o posix ; set ) > "${last_run_vars}"
  fi
}

exit_error ()
{
  # Exit and print message to STDERR
  echo_error "$1"
  # kill -9 $(ps -s $$ -o pid= | grep -v $$) 2>&-
  save_bash_variables
  db_connection_kill
  exit 1
}

trap_error ()
{
  # Trap any line that fails to run
  # echo_error "Error on line $1."
  local err=$?
  echo_error "Error in ${BASH_SOURCE[1]}:${BASH_LINENO[0]}. '${BASH_COMMAND}' exited with status $err"
  fc_def_empty_var moat370_error_file
  if [ -n "${moat370_error_file}" ]
  then
    echo "Error in ${BASH_SOURCE[1]}:${BASH_LINENO[0]}. '${BASH_COMMAND}' exited with status $err" >> "${moat370_error_file}"
  fi
}

trap_error ()
{
  local err=$?
  set +o xtrace
  local code="${1:-1}"
  echo_error "Error in ${BASH_SOURCE[1]}:${BASH_LINENO[0]}. '${BASH_COMMAND}' exited with status $err"
  # Print out the stack trace described by $function_stack  
  if [ ${#FUNCNAME[@]} -gt 2 ]
  then
    echo_error "Call tree:"
    for ((i=1;i<${#FUNCNAME[@]}-1;i++))
    do
      echo_error " $i: ${BASH_SOURCE[$i+1]}:${BASH_LINENO[$i]} ${FUNCNAME[$i]}(...)"
    done
  fi
}

bin_check_exit ()
{
  # Check if binary exists
  if ! bin_check $1
  then
  	exit_error "The \"$1\" command could not be found. Please add to PATH..."
  fi
}

bin_check ()
{
  # Check if binary exists
  if which $1 > /dev/null 2> /dev/null
  then
    return 0
  else
    return 1
  fi
}

var_check ()
{
  # Check if variable is defined
  if typeset -p "$1" >/dev/null 2>&1
  then
    return 0
  else
  	return 1
  fi
}

fc_def_empty_var ()
{
  if ! var_check "$1"
  then
    eval "$1=''"
  fi
}

fc_set_value_var_nvl ()
{
  if [ -n "$2" ]
  then
    eval $1=\$2
  else
    eval $1=\$3
  fi
}

fc_set_value_var_nvl2 ()
{
  ## 4 parameters are given, works similar to NVL2 function: param1 = NVL2(param2,param3,param4)
  ## NVL2 lets you determine the value returned by a query based on whether a specified expression is null or not null.
  ## If param2 is not null, then NVL2 returns param3. If param2 is null, then NVL2 returns param4.

  if [ -n "$2" ]
  then
    eval $1=\$3
  else
    eval $1=\$4
  fi
}

fc_set_value_var_decode ()
{
  ## Works as DECODE function: param1 = DECODE(param2,param3,param4,param5)
  ## Define variable in 1st parameter as 4th parameter if param2=param3. Else set as param5.
  
  if [ "$2" = "$3" ]
  then
    eval $1=\$4
  else
    eval $1=\$5
  fi
}

list_include_item ()
{
  list="$1"
  item="$2"
  if [[ $list =~ (^|,)"$item"($|,) ]]
  then
    return 0
  else
    return 1
  fi
}

fc_validate_variable ()
{
  ## Function that will check if passed variable in parameter 1 has the condition of parameter 2. Exit code if condition is not met.
  ## Valid conditions for parameter 2 are: "Y_N", "ON_OFF", "NOT_NULL", "UPPER_CASE", "LOWER_CASE", "T_D_N", "IS_NUMBER", "RANGE"
  local in_param="$1"
  local in_cond="$2"

  set +u
  local in_custom="$3"
  fc_enable_set_u

  eval in_param_content=\$${in_param}

  if ! list_include_item 'Y_N,ON_OFF,NOT_NULL,UPPER_CASE,LOWER_CASE,T_D_N,IS_NUMBER,RANGE' ${in_cond}
  then
    exit_error "Invalid 2nd parameter ${in_cond} on call of fc_validate_variable function."
  fi

  if [ "${in_cond}" = 'Y_N' ] && ! list_include_item 'Y,N' "${in_param_content}"
  then
    exit_error "Invalid value for ${in_param} : \"${in_param_content}\". Valid values are \"Y\" or \"N\"."
  fi

  if [ "${in_cond}" = 'ON_OFF' ] && ! list_include_item 'ON,OFF' "${in_param_content}"
  then
    exit_error "Invalid value for ${in_param} : \"${in_param_content}\". Valid values are \"ON\" or \"OFF\"."
  fi

  if [ "${in_cond}" = 'NOT_NULL' ] && [ -z "${in_param_content}" ]
  then
    exit_error "Variable ${in_param} must not be NULL. Please declare it on \"00_config.cfg\" file."
  fi

  if [ "${in_cond}" = 'UPPER_CASE' ] && [ "${in_param_content}" != "$(upper_var "${in_param_content}")" ]
  then
    exit_error "Variable ${in_param} must be upper case. Please correct it on \"00_config.cfg\" file."
  fi

  if [ "${in_cond}" = 'LOWER_CASE' ] && [ "${in_param_content}" != "$(lower_var "${in_param_content}")" ]
  then
    exit_error "Variable ${in_param} must be lower case. Please correct it on \"00_config.cfg\" file."
  fi

  if [ "${in_cond}" = 'T_D_N' ] && ! list_include_item 'T,D,N' "${in_param_content}"
  then
    exit_error "Invalid Oracle Pack License: \"${in_param_content}\". Valid values are T, D or N."
  fi

  if [ "${in_cond}" = 'IS_NUMBER' ] && ! [[ $in_param_content =~ ^[0-9]+$ ]]
  then
    exit_error "Variable ${in_param} must be a number. Please correct it on \"00_config.sql\" file."
  fi

  if [ "${in_cond}" = 'RANGE' ]
  then
    if [ -z "${in_custom}" ]
    then
      exit_error "Variable ${in_param} range values not specified. Please correct."
    else
      if ! list_include_item "${in_custom}" "${in_param_content}"
      then
        exit_error "Invalid value for ${in_param} : \"${in_param_content}\". Valid values are: ${in_custom}."
      fi
    fi
  fi

  unset in_param in_param_content in_cond in_custom
}

fc_def_output_file ()
{
  ## This code will adapt the filename to a correct patern to be used by the code.
  ## Param 1 = Variable name
  ## Param 2 = Filename

  local c_ofile_param1="$1"
  local c_ofile_param2="$2"

  eval $c_ofile_param1=${moat370_sw_output_fdr}/${c_ofile_param2}

  unset c_ofile_param1 c_ofile_param2
}

fc_seq_output_file ()
{
  ## This code will append to the variable provided in param1 the file sequence and the common_prefix.
  ## Param 1 = Variable name
  local in_param in_param_content v_file_name v_file_path v_result

  in_param="$1"

  eval in_param_content=\$${in_param}
  
  file_seq=$(do_calc "file_seq+1")
  
  v_file_path=''
  if [ $(instr_var "${in_param_content}" '/') -gt 0 ]
  then
    v_file_path=$(sed 's:[^/]*$::g' <<< "${in_param_content}")
  fi
  v_file_name=$(sed 's:.*/::' <<< "${in_param_content}")

  v_result="${v_file_path}$(printf %05d $file_seq)_${common_moat370_prefix}_${section_id}_${v_file_name}"

  v_result=$(sed 's/\(\_\)\1*/_/g' <<< "${v_result}") # Replace "__" with "_"
  v_result=$(sed 's/\_$//g' <<< "${v_result}")

  [ -f "${in_param_content}" ] && mv "${in_param_content}" "${v_result}"
  
  eval ${in_param}=\${v_result}
}

fc_exit_no_folder_perms ()
{
  ## Exit the program if target folder is not writable.
  
  if ! [ -w "${moat370_sw_output_fdr}" ]
  then
    exit_error "OUTPUT FOLDER "${moat370_sw_output_fdr}" NOT WRITABLE"
  fi
  
}

fc_clean_file_name ()
{
  ## Convert string on variable specified at parameter 1 to file_name string returned on variable specified on parameter 2
  ## Param 1 = Input Variable
  ## Param 2 = Output Variable
  ## Param 3 = (Optional) If defined to PATH, remove PATH from variable. If NULL clear file as usual.

  local in_param out_param type_param in_param_content

  in_param="$1"
  out_param="$2"

  set +u
  type_param="$3"
  fc_enable_set_u

  eval in_param_content=\$${in_param}

  out_param_content=${in_param_content}

  if [ "${type_param}" = 'PATH' ]
  then
    if [ $(instr_var "${in_param_content}" '/') -gt 0 ]
    then
      out_param_content=$(sed 's:.*/::' <<< "${out_param_content}")
    fi
  else
    out_param_content=$(tr -cd '[:alnum:]_' <<< "${out_param_content}")
    out_param_content=$(sed 's/\(\_\)\1*/_/g' <<< "${out_param_content}") # Replace "__" with "_"
  fi

  eval ${out_param}=\${out_param_content}
}

fc_load_db_functions ()
{
  source "${moat370_fdr_sh}"/${moat370_sw_db_type}_functions.sh
}

fc_section_variables ()
{
  local v_i v_j v_var v_res
  for v_i in {1..9}
  do
    for v_j in {97..107}
    do
      v_var=$($cmd_awk '{printf("%d%c",$1,$2)}' <<< "${v_i} ${v_j}")
      if [ "${v_var}" \> "${moat370_sec_from}" -o "${v_var}" = "${moat370_sec_from}" ] && \
         [ "${v_var}" \< "${moat370_sec_to}"   -o "${v_var}" = "${moat370_sec_to}" ]
      then
        v_res=''
      else
        v_res="--"
      fi
      eval ${moat370_sw_name}_${v_var}=\${v_res}
    done
  done
}

fc_zip_driver_files ()
{
  ## This code will save step files generated during MOAT369 execution for DEBUG.
  local in_file_full in_file_name in_file_path step_new_file_name
  in_file_full="$1"

  driver_seq=$(do_calc "driver_seq+1")

  fc_clean_file_name in_file_full in_file_name PATH

  if [ $(instr_var "${in_file_full}" '/') -gt 0 ]
  then
    in_file_path=$(sed 's:[^/]*$::' <<< "${in_file_full}")
  fi

  step_new_file_name="${in_file_path}$(printf %03d ${driver_seq})_${in_file_name}"

  mv ${in_file_full} ${step_new_file_name}

  fc_zip_file "${moat370_driver}" "${step_new_file_name}"

  unset in_file_full in_file_name in_file_path step_new_file_name
}

fc_reset_defaults ()
{
  ## Reset variables and defs used by each item.
  sql_text=''
  sql_text_display=''
  sql_with_clause=''
  input_file=''
  row_num='-1'
  row_num_dif=0
  abstract=''
  main_table=''
  foot=''
  max_rows="${moat370_def_sql_maxrows}"
  sql_hl="${moat370_def_sql_highlight}"
  sql_format="${moat370_def_sql_format}"
  sql_show="${moat370_def_sql_show}"
  sql_wait_secs="${moat370_def_sql_wait_secs}"
  ##
  skip_table="${moat370_def_skip_table}"
  skip_csv="${moat370_def_skip_csv}"
  skip_line="${moat370_def_skip_line}"
  skip_pie="${moat370_def_skip_pie}"
  skip_bar="${moat370_def_skip_bar}"
  skip_graph="${moat370_def_skip_graph}"
  skip_map="${moat370_def_skip_map}"
  skip_treemap="${moat370_def_skip_treemap}"
  skip_text="${moat370_def_skip_text}"
  skip_html="${moat370_def_skip_html}"
  output_type=''
  d3_graph=''
  ##
  title_suffix=''
  ##
  stacked=''
  haxis="${db_version} ${cores_threads_hosts}"
  vaxis=''
  vbaseline=''
  chartype=''
  ## needed reset after eventual sqlmon
  fc_db_reset_options
  ##
}

fc_wait_string ()
{
  local v_file v_string
  local v_start_time v_cur_time v_total_sleep v_sleep_time

  v_file="$1"
  v_string="$2"

  set +u
  local v_wait_limit="$3"
  fc_enable_set_u

  [ -z "${v_wait_limit}" ] && v_wait_limit=10 # Secs

  v_start_time=$(get_secs)
  v_sleep_time=0.5
  v_total_sleep=0

  set +x

  while :
  do
    if [ -f "${v_file}" ] && grep -q "${v_string}" "${v_file}"
    then
      break
    fi
    sleep ${v_sleep_time}
    v_cur_time=$(get_secs)
    v_total_sleep=$(do_calc "v_cur_time-v_start_time")
    if [ ${v_total_sleep} -gt ${v_wait_limit} ]
    then
      echo_error "Unable to get string ${v_string} on file ${v_file} after ${v_wait_limit} seconds."
      fc_enable_set_x
      return 1
    fi
    if ! db_connection_check
    then
      # If moat370_check_connection_status is true, will abort code execution if connection is dropped.
      # Otherwise will return 1
      ${moat370_check_connection_status} && exit_error "Lost DB connection." || return 1
    fi
  done

  fc_enable_set_x
  return 0
}

fc_load_column ()
{
  ## This code will check for all sections configured for a given column (parameter 1) and load them.
  local moat370_cur_col_id="$1"
  local moat370_sections_file="${moat370_sw_folder}/cfg/00_sections.csv"
  local v_csv_1 v_csv_2 v_csv_3 v_csv_4 v_list

  ## The variable below will be changed to YES if the code ever enter in 9a
  moat370_column_print='NO'
  
  if ${cmd_grep} -q -e "^${moat370_cur_col_id}" ${moat370_sections_file}
  then
    v_list=$(${cmd_grep} -e "^${moat370_cur_col_id}" ${moat370_sections_file} | ${cmd_awk} -F',' '{print $2}')
  fi

  for v_csv_2 in ${v_list}
  do
    v_line=$(${cmd_grep} -e ",${v_csv_2}," ${moat370_sections_file})
    v_csv_1=$(${cmd_awk} -F',' '{print $1}' <<< "${v_line}")
    v_csv_3=$(${cmd_awk} -F',' '{print $3}' <<< "${v_line}")
    v_csv_4=$(${cmd_awk} -F',' '{print $4}' <<< "${v_line}")
    
    set +u
    eval v_skip="${v_csv_4}\${${moat370_sw_name}_${v_csv_1}}"
    fc_enable_set_u

    if [ -z ${v_skip} ]
    then
      fc_call_section "${v_csv_1}" "${v_csv_2}" "${v_csv_3}"
    fi
  done

  unzip "${moat370_zip_filename}" "${moat370_style_css}" -d "${moat370_sw_output_fdr}" >> "${moat370_log3}"
  if [ "${moat370_column_print}" = "NO" ]
  then
    echo "td.i${moat370_cur_col_id}            {display:none;}" >> "${moat370_sw_output_fdr}/${moat370_style_css}"
  elif [ "${moat370_column_print}" = "YES" ]
  then
    echo "td.i${moat370_cur_col_id}            {}" >> "${moat370_sw_output_fdr}/${moat370_style_css}"
  fi

  fc_zip_file "${moat370_zip_filename}" "${moat370_sw_output_fdr}/${moat370_style_css}"

  unset moat370_cur_col_id moat370_sections_file moat370_column_print
}

fc_encode_html ()
{
  ## Parameter 1 : HTML file to be encrypted
  ## Parameter 2 : Optional parameter. If not null, means this is the first index page and add a the application logo
  local in_enc_html_src_file="$1"
  local enc_html_template_file step_enc_html_file

  set +u
  local in_custom="$2"
  fc_enable_set_u

  if [ -z "${in_custom}" ]
  then
    enc_html_template_file="${moat370_fdr_cfg}/moat370_html_encoded.html"
  else
    enc_html_template_file="${moat370_fdr_cfg}/moat370_html_encoded_index.html"
  fi

  ## This is necessary to resolve the variables inside the enc_html_template_file.
  fc_def_output_file step_enc_html_file 'step_enc_html_template.html'
  rm -f "${step_enc_html_file}"

  fc_paste_file_replacing_variables "${enc_html_template_file}" "${step_enc_html_file}"

  ### Encode html.
  fc_encode_html_internal "${in_enc_html_src_file}" "${step_enc_html_file}" "${enc_key_file}" "${moat370_conf_encrypt_html}" "${moat370_conf_compress_html}"

  rm -f "${step_enc_html_file}"
  unset step_enc_html_file in_enc_html_src_file enc_html_template_file
}

fc_encode_html_internal ()
{
  # 1 = Input file with BEGIN_SENSITIVE_DATA and END_SENSITIVE_DATA tags. Output file will be the same, replaced.
  # 2 = Encoded HTML template.
  # 3 = Key File used OpenSSL for encryption.
  # 4 = Enable Encryption? ON or OFF
  # 5 = Enable Comprssion? ON or OFF

  if [ $# -ne 5 ]
  then
    echo_error "Five arguments are needed..."
    return 1
  fi

  local in_file=$1
  local enc_file=$2
  local x_file=$3
  local flag_encr=$4
  local flag_comp=$5
  local out_tmp_file=$1.tmp.html

  [ "$flag_encr" = "ON" -o "$flag_encr" = "OFF" ] || return 1
  [ "$flag_comp" = "ON" -o "$flag_comp" = "OFF" ] || return 1

  # Nothing to do here.
  [ "$flag_encr" = "ON" -o "$flag_comp" = "ON" ] || return 0

  test -f "${in_file}" || return 1
  test -f "${enc_file}" || return 1

  if [ "$flag_encr" = "ON" ]
  then
    bin_check openssl || return 1
    [ -f "${x_file}" ] || return 1
  fi
  if [ "$flag_comp" = "ON" ]
  then
    bin_check gzip || return 1
    bin_check base64 || return 1
  fi

  in_start_line=`${cmd_sed} -ne /\<!--BEGIN_SENSITIVE_DATA--\>/= "${in_file}"`
  in_stop_line=`${cmd_sed} -ne /\<!--END_SENSITIVE_DATA--\>/= "${in_file}"`
  in_last_line=`cat "${in_file}" | wc -l`
  enc_vars_line=`${cmd_sed} -ne /encoded_vars/= "${enc_file}"`
  enc_hash_line=`${cmd_sed} -ne /encoded_data/= "${enc_file}"`
  enc_last_line=`cat "${enc_file}" | wc -l`

  test -n "${in_start_line}" || return 1
  test -n "${in_stop_line}"  || return 1
  test -n "${in_last_line}"  || return 1
  test -n "${enc_vars_line}" || return 1
  test -n "${enc_hash_line}" || return 1
  test -n "${enc_last_line}" || return 1

  ${cmd_awk} "NR >= 1 && NR < $in_start_line {print;}" "${in_file}" > "${out_tmp_file}"
  ${cmd_awk} "NR >= 1 && NR < $enc_vars_line {print;}" "${enc_file}" >> "${out_tmp_file}"
  [ "$flag_encr" = "ON" ] && echo "var enctext_encr = true" >> "${out_tmp_file}" || echo "var enctext_encr = false" >> "${out_tmp_file}"
  [ "$flag_comp" = "ON" ] && echo "var enctext_comp = true" >> "${out_tmp_file}" || echo "var enctext_comp = false" >> "${out_tmp_file}"
  ${cmd_awk} "NR > $enc_vars_line && NR < $enc_hash_line {print;}" "${enc_file}" >> "${out_tmp_file}"
  ###
  if [ "$flag_encr" = "ON" -a "$flag_comp" = "ON" ]
  then
    ${cmd_awk} "NR > $in_start_line && NR < $in_stop_line {print;}" "${in_file}" | gzip -cf | base64 | openssl enc -aes256 -a -salt -pass file:${x_file} | ${cmd_sed} "s/^/'/" | ${cmd_sed} "s/$/'/" | ${cmd_sed} -e 's/$/ +/' -e '$s/ +$//' >> "${out_tmp_file}"
  elif [ "$flag_encr" = "ON" -a "$flag_comp" = "OFF" ]
  then
    ${cmd_awk} "NR > $in_start_line && NR < $in_stop_line {print;}" "${in_file}" | openssl enc -aes256 -a -salt -pass file:${x_file} | ${cmd_sed} "s/^/'/" | ${cmd_sed} "s/$/'/" | ${cmd_sed} -e 's/$/ +/' -e '$s/ +$//' >> "${out_tmp_file}"
  elif [ "$flag_encr" = "OFF" -a "$flag_comp" = "ON" ]
  then
    ${cmd_awk} "NR > $in_start_line && NR < $in_stop_line {print;}" "${in_file}" | gzip -cf | base64 | ${cmd_sed} "s/^/'/" | ${cmd_sed} "s/$/'/" | ${cmd_sed} -e 's/$/ +/' -e '$s/ +$//' >> "${out_tmp_file}"
  fi
  ###
  ${cmd_awk} "NR > $enc_hash_line && NR <= $enc_last_line {print;}" "${enc_file}" >> "${out_tmp_file}"
  ${cmd_awk} "NR > $in_stop_line && NR <= $in_last_line {print;}" "${in_file}" >> "${out_tmp_file}"

  mv "${out_tmp_file}" "${in_file}"

}

fc_paste_file_replacing_variables ()
{
  local v_source_file="$1"
  local v_target_file="$2"
  eval "cat <<EOF
$(<"${v_source_file}")
EOF
" >> "${v_target_file}"
}

fc_zip_file ()
{
  # 1 = Source File
  # 2 = Target Zip File
  # 3 = Move? True or False. Default True
  # 4 = Relative Path? True or False. Default True

  local v_zip="$1"
  local v_src="$2"

  set +u
  local v_move="$3"
  local v_relative="$4"
  fc_enable_set_u

  [ ! -f "${v_src}" ] && return

  [ -z "${v_move}" ] && v_move='true'
  [ -z "${v_relative}" ] && v_relative='true'

  v_param=''
  ${v_move} && v_param="${v_param} -m"
  ${v_relative} && v_param="${v_param} -j"

  zip ${v_param} "${v_zip}" "${v_src}" >> "${moat370_log3}"
}

fc_encrypt_file_internal ()
{
  ## This code will check if parameter 1 has a valid file. If it does, it will encrypt the file and update the input parameter with the new name.
  local in_param in_param_content out_enc_file
  in_param="$1"

  eval in_param_content=\$${in_param}

  out_enc_file="${in_param_content}.enc"

  openssl smime -encrypt -binary -aes-256-cbc -in "${in_param_content}" -out "${out_enc_file}" -outform DER "${moat370_enc_pub_file}"
  
  if [ -f "${out_enc_file}" ]
  then
    rm -f "${in_param_content}"
    eval ${in_param}=\${out_enc_file}
  fi

  unset in_param in_param_content out_enc_file
}

fc_call_section ()
{
  ## This code will call a section and print it.
  ## Param 1 = Section ID 
  ## Param 2 = Section Name
  ## Param 3 = File Name

  local moat370_sec_id="$1"
  local moat370_sec_fl="$2"
  local moat370_sec_nm="$3"

  fc_db_pre_section_call

  section_id="${moat370_sec_id}"
  section_name="${moat370_sec_nm}"
  
  fc_db_define_module

  local v_file="${moat370_sw_folder}/sh/${moat370_sec_fl}" 

  [ ! -f "${v_file}" ] && exit_error "File \"${v_file}\" does not exist. Fix 00_sections.csv."

  ## The variable below will be changed to YES if the code ever enter in 9a
  moat370_section_print='NO'

  echo "<h2 class=\"i${section_id}\">${section_id}. ${section_name}</h2>" >> "${moat370_main_report}"
  echo "<ol start=\"${report_sequence}\">" >> "${moat370_main_report}"

  ## Reset section related DEFs
  fc_db_reset_options

  # fc_def_output_file section_fifo "${moat370_sec_id}_sec_fifo.sh"
  fc_def_output_file section_fifo "${moat370_sec_id}_sec.sh"
  rm -f "${section_fifo}"
  # mkfifo "${section_fifo}"
  if [ "${moat370_sw_enc_sql}" = 'Y' ]
  then
    cat "${moat370_sw_folder}/sh/${moat370_sec_fl}" | openssl enc -d -aes256 -a -salt -pass file:${moat370_enc_pub_file} > ${section_fifo} #&
  else
    echo "source \"${moat370_sw_folder}/sh/${moat370_sec_fl}\"" > ${section_fifo} #&
  fi

  source "${section_fifo}"

  rm "${section_fifo}"

  echo "</ol>" >> "${moat370_main_report}"

  unzip "${moat370_zip_filename}" "${moat370_style_css}" -d "${moat370_sw_output_fdr}" >> "${moat370_log3}"
  if [ "${moat370_section_print}" = "NO" ]
  then
    echo "h2.i${section_id}            {display:none;}" >> "${moat370_sw_output_fdr}/${moat370_style_css}"
  elif [ "${moat370_section_print}" = "YES" ]
  then
    echo "h2.i${section_id}            {}" >> "${moat370_sw_output_fdr}/${moat370_style_css}"
  fi

  fc_zip_file "${moat370_zip_filename}" "${moat370_sw_output_fdr}/${moat370_style_css}"

  unset section_id section_name section_fifo
  unset moat370_sec_id moat370_sec_fl moat370_sec_nm
}

fc_echo_screen_log ()
{
  v_text="$1"
  [ "${v_text}" = "division" ] && v_text="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  echo "${v_text}" | tee -a "${moat370_log}"
}

fc_check_database_variables ()
{
  var_check "hosts_count" || exit_error "Function fc_db_begin_code must define hosts_count variable."
  var_check "avg_core_count" || exit_error "Function fc_db_begin_code must define avg_core_count variable."
  var_check "avg_thread_count" || exit_error "Function fc_db_begin_code must define avg_thread_count variable."
  var_check "database_name" || exit_error "Function fc_db_begin_code must define database_name variable."
  var_check "host_name" || exit_error "Function fc_db_begin_code must define host_name variable."
  var_check "db_version" || exit_error "Function fc_db_begin_code must define db_version variable."
}

fc_convert_txt_to_html ()
{
  ## This code will check if parameter 1 has a valid file. If it does, it will convert the file to html and update the input parameter with the new name.
  local in_param="$1"
  local in_param_content

  eval in_param_content=\$${in_param}

  if [ -f "${in_param_content}" ]
  then
    fc_convert_txt_to_html_internal "${in_param_content}"
  fi

  if [ -f "${in_param_content}.html" ]
  then
    eval ${in_param}="${in_param_content}.html"
  fi

  unset in_param in_param_content
}

fc_convert_txt_to_html_internal ()
{
  if [ $# -ne 1 ]
  then
    echo "One argument is needed..."
    return 1
  fi

  in_file="$1"
  out_file="$1.html"

  test -f "$in_file" || return 1

  touch "$out_file"

  echo '<html><head></head><body>'                                                       >  "$out_file"
  echo '<!--BEGIN_SENSITIVE_DATA-->'                                                     >> "$out_file"
  echo '<pre style="word-wrap: break-word; white-space: pre-wrap;">'                     >> "$out_file"
  fc_escape_markup_characters "$in_file"                                                 >> "$out_file"
  echo '</pre>'                                                                          >> "$out_file"
  echo '<!--END_SENSITIVE_DATA-->'                                                       >> "$out_file"
  echo '</body></html>'                                                                  >> "$out_file"

  test -f "$out_file" || return 1

  rm -f "$in_file"
  ###
}

fc_escape_markup_characters ()
{
  $cmd_sed 's|\&|\&amp;|g; s|>|\&gt;|g; s|<|\&lt;|g' "$1"
}

fc_is_set_control_enabled ()
{
  local v_set
  #v_set=$(printf %s\\n "$-")
  v_set=$(printf %s "$-")
  if grep -q "$1" <<< "${v_set}"
  then
    echo "true"
  else
    echo "false"
  fi
}

fc_disable_all_sets ()
{
  set +u
  set +x
}

fc_enable_all_sets ()
{
  fc_enable_set_u
  fc_enable_set_x
}

fc_enable_set_x ()
{
  if ${moat370_code_set_x}
  then
    set -x
  fi
}

fc_enable_set_u ()
{
  if ${moat370_code_set_u}
  then
    set -u
  fi
}

fc_connection_flow ()
{
  local moat370_max_retries=5
  fc_def_empty_var moat370_reconnections

  moat370_reconnections=$(do_calc "moat370_reconnections+1")

  if [ ${moat370_reconnections} -gt ${moat370_max_retries} ]
  then
    exit_error "Maximum reconnection limit reached (${moat370_max_retries})."
  else
    [ ${moat370_reconnections} -ne 1 ] && echo_time "Reconnecting.. ${moat370_reconnections}/${moat370_max_retries}"
  fi

  fc_db_startup_connection
  [ "${moat370_sw_db_type}" != "offline" ] && echo_time "Starting ${moat370_sw_db_type} in background. Connecting..."
  fc_db_check_connection
  [ "${moat370_sw_db_type}" != "offline" ] && echo_time "Connected."
  fc_db_begin_code
  [ "${moat370_sw_db_type}" != "offline" ] && echo_time "Loaded database startup code."
  fc_check_database_variables
}

fc_replace_file_variable ()
{
  local v_in_file="$1"
  local v_in_attr=$(ere_quote "$2")
  local v_in_repl=$(ere_quote "$3")
  local v_out_file="${v_in_file}.tmp"

  sed "s|${v_in_attr}|${v_in_repl}|g" "${v_in_file}" > "${v_out_file}"

  mv "${v_out_file}" "${v_in_file}"
}

#### END OF FILE ####