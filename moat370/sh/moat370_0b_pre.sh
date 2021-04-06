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

## Check what set controls are enabled in the code.
moat370_code_set_x=$(fc_is_set_control_enabled 'x')
moat370_code_set_u=$(fc_is_set_control_enabled 'u')

## Define current code version:
source "${moat370_fdr}"/cfg/version.cfg

## Define all functions and files:
source "${moat370_fdr}"/cfg/moat370_fc_define_files.cfg

## Exit if not connected to a database
# database_check_connected

moat370_fw_vYYYY=`date +%Y`

## Check command line parameter - This must come as soon as possible to avoid subsqls from overriding parameters. Do not call any parametered function or fc_set_term_off before.
set +u
in_main_param1="${v_parameters[0]}"
in_main_param2="${v_parameters[1]}"
in_main_param3="${v_parameters[2]}"
in_main_param4="${v_parameters[3]}"
in_main_param5="${v_parameters[4]}"
fc_enable_set_u

## Start Time - Do not move it to the beggining, b4 we must ensure we are connected.
moat370_main_time0=$(get_secs)

## Define SW folder and load configurations:
fc_def_empty_var moat370_pre_sw_base
# fc_set_value_var_nvl 'moat370_fdr' "${moat370_pre_sw_base}" "./"
fc_set_value_var_nvl 'moat370_fdr' "${moat370_pre_sw_base}" "${moat370_fdr}"

fc_def_empty_var moat370_pre_sw_folder
#fc_set_value_var_nvl 'moat370_sw_folder' "${moat370_pre_sw_folder}" "${moat370_fdr}/sql"
fc_set_value_var_nvl 'moat370_sw_folder' "${moat370_pre_sw_folder}" "."
if [ -f "${moat370_sw_folder}/cfg/00_software.cfg" ]
then
  source "${moat370_sw_folder}/cfg/00_software.cfg"
else
  exit_error "Could not find \"${moat370_sw_folder}/cfg/00_software.cfg\"."
fi
[ -f "${moat370_sw_folder}/cfg/00_config.cfg" ] && source "${moat370_sw_folder}/cfg/00_config.cfg"

## Validate config file -> Must run after variables 1 and 2 are saved.
source "${fc_check_config}"

## Define error file.
fc_def_output_file moat370_error_file 'error.txt'
rm -f "${moat370_error_file}"

## Define full output folder path.
moat370_sw_output_fdr_fpath="$(cd -P "${moat370_sw_output_fdr}"; pwd)"

## Parse parameters
source "${fc_parse_parameters}"
unset in_main_param1 in_main_param2 in_main_param3 in_main_param4 in_main_param5

fc_validate_variable moat370_sw_db_type RANGE sqlplus,sqlcl,mysql,postgres,offline
fc_validate_variable moat370_sw_db_conn_params NOT_NULL

## Override moat370_sections with sections_param if provided
fc_set_value_var_nvl 'sections_param' "${sections_param}" "${moat370_sections}"
moat370_sections="${sections_param}"
## unset sections_param -- Commented for better debugging

## Start
if [ "${moat370_conf_ask_license}" = 'Y' ]
then
  echo If your Database is licensed to use the Oracle Tuning pack please enter T.
  echo If you have a license for Diagnostics pack but not for Tuning pack, enter D.
  echo Be aware value N reduces the output content substantially. Avoid N if possible.
  echo
fi

if [ "${moat370_conf_ask_license}" = 'Y' ] && [ -z "${license_pack_param}" ]
then
  read -p "Oracle Pack License? (Tuning, Diagnostics or None) [ T | D | N ] (required): " license_pack_param
  fc_set_value_var_nvl license_pack_param "${license_pack_param}" '?'
fi

license_pack_param=$(trim_var "${license_pack_param}")
license_pack_param=$(upper_var "${license_pack_param}")

fc_set_value_var_nvl 'license_pack' ${license_pack_param} "N"

fc_validate_variable license_pack T_D_N

if list_include_item 'T,D' ${license_pack}
then
  diagnostics_pack='Y'
  skip_diagnostics=''
else
  diagnostics_pack='N'
  skip_diagnostics="--"
fi

## -- -- -- -- --

if [ "${license_pack}" = 'T' ]
then
  tuning_pack='Y'
  skip_tuning=''
else
  tuning_pack='N'
  skip_tuning="--"
fi

if [ "${license_pack}" = 'N' ] && [ "${moat370_conf_ask_license}" = 'Y' ]
then
  echo 'Be aware value "N" reduces output content substantially. Avoid "N" if possible.'
  sleep 5
fi

## Move it away from here
## COL fc_get_dbvault_user NEW_V fc_get_dbvault_user
## select case WHEN COUNT(*)=1 then '' ELSE "--" END || "${fc_get_dbvault_user}" fc_get_dbvault_user from v$option where parameter='Oracle Database Vault' and value='TRUE'
## COL fc_get_dbvault_user clear
## source ${fc_get_dbvault_user}

## Final file will be only encrypted if defined by parameter
if [ "${moat370_conf_encrypt_output}" = 'ON' ]
then
  fc_encrypt_output_zip () { fc_encrypt_file_internal "$@"; }
  moat370_conf_encrypt_html='OFF' # If output zip is already being encrypted, there is no reason to enable HTML encryption.
else
  fc_encrypt_output_zip () { true; }
fi

## Mid non-html files and files converted to html are encrypted based on html encryption
if [ "${moat370_conf_encrypt_html}" = 'ON' ]
then
  fc_encrypt_file () { fc_encrypt_file_internal "$@"; }
else
  fc_encrypt_file () { true; }
fi

##
if [ "${moat370_conf_encrypt_html}" = 'OFF' ] && [ "${moat370_conf_compress_html}" = 'OFF' ]
then
  fc_convert_txt_to_html () { true; }
fi

##
if [ "${moat370_conf_tablefilter}" = 'Y' ]
then
  fc_add_sorttable () { true; }
else
  fc_add_tablefilter () { true; }
fi

fc_def_empty_var moat370_pre_enc_pub_file
fc_set_value_var_nvl 'moat370_enc_pub_file' "${moat370_pre_enc_pub_file}" "${moat370_sw_folder}/cfg/${moat370_sw_cert_file}"

fc_def_empty_var moat370_pre_sw_key_file
fc_def_output_file enc_key_file 'key.bin'
fc_set_value_var_nvl 'enc_key_file' "${moat370_pre_sw_key_file}" "${enc_key_file}"

if [ "${moat370_conf_encrypt_html}" = 'ON' -o "${moat370_conf_encrypt_output}" = 'ON' ] \
&& [ -z "${moat370_sw_cert_file}" ]
then
  echo_error "\"moat370_conf_encrypt_html\" or \"moat370_conf_encrypt_output\" is ON but no certification file specified on \"moat370_sw_cert_file\". Encryption will be disabled."
  moat370_conf_encrypt_html='OFF'
  moat370_conf_encrypt_output='OFF'
fi

if [ "${moat370_conf_encrypt_html}" = 'ON' -o "${moat370_conf_encrypt_output}" = 'ON' ] \
&& [ ! -f "${moat370_enc_pub_file}" ]
then
  echo_error "\"moat370_conf_encrypt_html\" or \"moat370_conf_encrypt_output\" is ON but no certification file found on \"${moat370_enc_pub_file}\". Encryption will be disabled."
  moat370_conf_encrypt_html='OFF'
  moat370_conf_encrypt_output='OFF'
fi  

if [ ! -f "${enc_key_file}" ] && [ "${moat370_conf_encrypt_html}" = 'ON' ]
then
  openssl rand -base64 32 -out "${enc_key_file}"
fi

if [ -f "${enc_key_file}" ] && [ -f "${moat370_enc_pub_file}" ]
then
  openssl rsautl -encrypt -inkey "${moat370_enc_pub_file}" -certin -in "${enc_key_file}" -out "${enc_key_file}.enc"
fi

## End Check Encryption

## Define OS binaries

[ -f /usr/xpg4/bin/awk ] && cmd_awk=/usr/xpg4/bin/awk || cmd_awk=awk
[ -f /usr/gnu/bin/grep ] && cmd_grep=/usr/gnu/bin/grep || cmd_grep=grep
[ -f /usr/xpg4/bin/sed ] && cmd_sed=/usr/xpg4/bin/sed || cmd_sed=sed

# GAWK is needed for SunOS and OSX
SOTYPE=$(uname -s)
if [ "$SOTYPE" = "SunOS" -o "$SOTYPE" = "Darwin" ]
then
  cmd_gawk=gawk
else
  cmd_gawk=${cmd_awk}
fi

bin_check_exit ${cmd_awk}
bin_check_exit ${cmd_grep}
bin_check_exit ${cmd_sed}
bin_check_exit ${cmd_gawk}

cmd_awk_awk_func_dir="${moat370_fdr_sh}/csv-parser.awk"
cmd_awk_param="-f ${cmd_awk_awk_func_dir} -v separator=, -v enclosure=\""
cmd_awk_csv="${cmd_gawk} ${cmd_awk_param}"

##
## Use default value of 31 unless you have been instructed otherwise.
##
## range: takes at least 31 days and at most as many as actual history, with a default of 31. parameter restricts within that range.
## Original query commented. If the tool is AWR based, move and adapt it to pre sql specific of the tool
##SELECT TO_CHAR(LEAST(CEIL(SYSDATE - CAST(MIN(begin_interval_time) AS DATE)), GREATEST(31, TO_NUMBER(NVL(TRIM("${moat370_conf_days}"), '31'))))) history_days FROM dba_hist_snapshot WHERE "${diagnostics_pack}"='Y' AND dbid=(SELECT dbid FROM v$database)
history_days=$(greatest_num 31 "${moat370_conf_days}")
history_secs=$(do_calc "${history_days}*24*60*60")

if [ "${moat370_conf_date_from}" != 'YYYY-MM-DD' ]
then
  check_input_format "${moat370_conf_date_from}"
fi

if [ "${moat370_conf_date_to}" != 'YYYY-MM-DD' ]
then
  check_input_format "${moat370_conf_date_to}"
fi

if [ "${moat370_conf_date_from}" != 'YYYY-MM-DD' ] && [ "${moat370_conf_date_to}" != 'YYYY-MM-DD' ]
then
  v_epoch_conf_date_from=$(ConvYMDToEpoch "${moat370_conf_date_from}")
  v_epoch_conf_date_to=$(ConvYMDToEpoch "${moat370_conf_date_to}")
  if [ ${v_epoch_conf_date_from} -gt ${v_epoch_conf_date_to} ]
  then
    exit_error "moat370_conf_date_from is greater then moat370_conf_date_to."
  fi
  history_secs=$(do_calc "${v_epoch_conf_date_to}-${v_epoch_conf_date_from}")
  history_days=$(ConvSecsToDays ${history_secs})
  history_days=$(do_calc "${history_days}+1")
fi

hist_work_days=$(do_calc "history_days*5/7")

## Dates format
moat370_date_format='+%Y-%m-%d/%H:%M:%S'
moat370_db_date_format='YYYY-MM-DD"T"HH24:MI:SS'

v_today=$(date "+%Y-%m-%d")
v_epoch_today=$(ConvYMDToEpoch "${v_today}")

if [ "${moat370_conf_date_from}" = 'YYYY-MM-DD' ]
then
  moat370_date_from=$(ConvEpochToYMD $(do_calc "v_epoch_today-history_secs"))
else
  moat370_date_from="${moat370_conf_date_from}"
fi

if [ "${moat370_conf_date_to}" = 'YYYY-MM-DD' ]
then
  moat370_date_to=$(ConvEpochToYMD $(do_calc "v_epoch_today+(24*60*60)"))
else
  moat370_date_to="${moat370_conf_date_to}"
fi

moat370_sections=$(lower_var "${moat370_sections}")

if [ ${#moat370_sections} -gt 5 -o ${#moat370_sections} -eq 0 ]
then
  moat370_sec_from='1a'
  moat370_sec_to='9z'
elif [ ${#moat370_sections} -eq 5 ] && \
     [ "$(substr_var "${moat370_sections}" 3 1)" = "-" ] && \
     [ "$(substr_var "${moat370_sections}" 1 2)" \> "1a" -o "$(substr_var "${moat370_sections}" 1 2)" = "1a" ] && \
     [ "$(substr_var "${moat370_sections}" 1 2)" \< "9z" -o "$(substr_var "${moat370_sections}" 1 2)" = "9z" ] && \
     [ "$(substr_var "${moat370_sections}" 4 2)" \> "1a" -o "$(substr_var "${moat370_sections}" 4 2)" = "1a" ] && \
     [ "$(substr_var "${moat370_sections}" 4 2)" \< "9z" -o "$(substr_var "${moat370_sections}" 4 2)" = "9z" ]
then # i.e. 1a-7b
  moat370_sec_from=$(substr_var "${moat370_sections}" 1 2)
  moat370_sec_to=$(substr_var "${moat370_sections}" 4 2)
elif [ ${#moat370_sections} -eq 4 ] && \
     [ "$(substr_var "${moat370_sections}" 3 1)" = "-" ] && \
     [ "$(substr_var "${moat370_sections}" 1 2)" \> "1a" -o "$(substr_var "${moat370_sections}" 1 2)" = "1a" ] && \
     [ "$(substr_var "${moat370_sections}" 1 2)" \< "9z" -o "$(substr_var "${moat370_sections}" 1 2)" = "9z" ] && \
     [ "$(substr_var "${moat370_sections}" 4 1)" \> "1" -o "$(substr_var "${moat370_sections}" 4 1)" = "1" ] && \
     [ "$(substr_var "${moat370_sections}" 4 1)" \< "9" -o "$(substr_var "${moat370_sections}" 4 1)" = "9" ]
then ## i.e. 3b-7
  moat370_sec_from=$(substr_var "${moat370_sections}" 1 2)
  moat370_sec_to=$(substr_var "${moat370_sections}" 4 1)z
elif [ ${#moat370_sections} -eq 4 ] && \
     [ "$(substr_var "${moat370_sections}" 2 1)" = "-" ] && \
     [ "$(substr_var "${moat370_sections}" 1 1)" \> "1" -o "$(substr_var "${moat370_sections}" 1 1)" = "1" ] && \
     [ "$(substr_var "${moat370_sections}" 1 1)" \< "9" -o "$(substr_var "${moat370_sections}" 1 1)" = "9" ] && \
     [ "$(substr_var "${moat370_sections}" 3 2)" \> "1a" -o "$(substr_var "${moat370_sections}" 3 2)" = "1a" ] && \
     [ "$(substr_var "${moat370_sections}" 3 2)" \< "9z" -o "$(substr_var "${moat370_sections}" 3 2)" = "9z" ]
then ## i.e. 3-5b
  moat370_sec_from=$(substr_var "${moat370_sections}" 1 1)a
  moat370_sec_to=$(substr_var "${moat370_sections}" 3 2)
elif [ ${#moat370_sections} -eq 3 ] && \
     [ "$(substr_var "${moat370_sections}" 2 1)" = "-" ] && \
     [ "$(substr_var "${moat370_sections}" 1 1)" \> "1" -o "$(substr_var "${moat370_sections}" 1 1)" = "1" ] && \
     [ "$(substr_var "${moat370_sections}" 1 1)" \< "9" -o "$(substr_var "${moat370_sections}" 1 1)" = "9" ] && \
     [ "$(substr_var "${moat370_sections}" 3 1)" \> "1" -o "$(substr_var "${moat370_sections}" 3 1)" = "1" ] && \
     [ "$(substr_var "${moat370_sections}" 3 1)" \< "9" -o "$(substr_var "${moat370_sections}" 3 1)" = "9" ]
then ## i.e. 3-5
  moat370_sec_from=$(substr_var "${moat370_sections}" 1 1)a
  moat370_sec_to=$(substr_var "${moat370_sections}" 3 1)z
elif [ ${#moat370_sections} -eq 2 ] && \
     [ "$(substr_var "${moat370_sections}" 1 2)" \> "1a" -o "$(substr_var "${moat370_sections}" 1 2)" = "1a" ] && \
     [ "$(substr_var "${moat370_sections}" 1 2)" \< "9z" -o "$(substr_var "${moat370_sections}" 1 2)" = "9z" ]
then ## i.e. 7b
  moat370_sec_from=$(substr_var "${moat370_sections}" 1 2)
  moat370_sec_to=${moat370_sec_from}
elif [ ${#moat370_sections} -eq 1 ] && \
     [ "$(substr_var "${moat370_sections}" 1 1)" \> "1" -o "$(substr_var "${moat370_sections}" 1 1)" = "1" ] && \
     [ "$(substr_var "${moat370_sections}" 1 1)" \< "9" -o "$(substr_var "${moat370_sections}" 1 1)" = "9" ]
then ## i.e. 7
  moat370_sec_from=$(substr_var "${moat370_sections}" 1 1)a
  moat370_sec_to=$(substr_var "${moat370_sections}" 1 1)z
else ## wrong use of hidden parameter
  moat370_sec_from='1a'
  moat370_sec_to='9z'
fi

# trace
fc_set_value_var_decode skip_trace "${moat370_conf_incl_trace}" 'Y' '' "--"

## filename prefix
if [ "${moat370_sec_from}" != "1a" -o "${moat370_sec_to}" != "9z" ]
then
  moat370_prefix="${moat370_sw_name}_${moat370_sec_from}_${moat370_sec_to}"
else
  moat370_prefix="${moat370_sw_name}"
fi

## Startup DB Connection
fc_def_empty_var v_db_client_pid
fc_load_db_functions
fc_connection_flow

## get database name (up to 10, stop before first '.', no special characters)
database_name_short=$(lower_var "${database_name}")
database_name_short=$(substr_var "${database_name_short}" 1 10)
dot_pos=$(instr_var "${database_name_short}" '.')
if [ $dot_pos -gt 1 ]
then
  dot_pos=$(do_calc "${dot_pos}-1")
  database_name_short=$(substr_var "${database_name_short}" 1 $dot_pos)
fi
database_name_short=$(tr -cd '[:alnum:]_-' <<< "${database_name_short}")

## get host name (up to 30, stop before first '.', no special characters)
host_name_short=$(lower_var "${host_name}")
host_name_short=$(substr_var "${host_name_short}" 1 30)
dot_pos=$(instr_var "${host_name_short}" '.')
if [ $dot_pos -gt 1 ]
then
  dot_pos=$(do_calc "${dot_pos}-1")
  database_name_short=$(substr_var "${host_name_short}" 1 $dot_pos)
fi
host_name_short=$(tr -cd '[:alnum:]_-' <<< "${host_name_short}")

## setup
sql_trace_level='1'
title=''
title_suffix=''

## timestamp on filename
moat370_file_time=$(get_date_time)

[ "${moat370_sw_db_type}" = "offline" ] && moat370_sw_dbtool='N'
fc_set_value_var_decode common_moat370_prefix "${moat370_sw_dbtool}" 'Y' "${moat370_prefix}_${database_name_short}" "${moat370_prefix}"

section_id=''

fc_def_output_file moat370_readme      '00000_readme_first.txt'
fc_def_output_file moat370_main_report 'index.html'
fc_def_output_file moat370_log         'log.txt'
fc_def_output_file moat370_log2        'time_log.txt'
fc_def_output_file moat370_log3        'zip_log.txt'
fc_def_output_file moat370_trace       'trace'
fc_def_output_file moat370_alert       'alert'
fc_def_output_file moat370_opatch      'opatch.zip'
fc_def_output_file moat370_driver      'drivers.zip'

fc_set_value_var_decode moat370_main_filename "${moat370_sw_dbtool}" 'Y' "${common_moat370_prefix}_${host_name_short}" "${common_moat370_prefix}"

fc_def_output_file moat370_zip_filename "${moat370_main_filename}_${moat370_file_time}.zip"
moat370_tracefile_identifier="${common_moat370_prefix}"
fc_def_output_file moat370_query '${common_moat370_prefix}_query.sql'

fc_def_empty_var moat370_pre_sw_output_file
fc_set_value_var_nvl 'moat370_zip_filename' "${moat370_pre_sw_output_file}" "${moat370_zip_filename}"

fc_def_empty_var exec_seq
fc_set_value_var_decode exec_seq "${exec_seq}" '' "1" "$(do_calc 'exec_seq+1')"

fc_def_empty_var file_seq
fc_set_value_var_nvl file_seq "${file_seq}" 0

fc_seq_output_file moat370_main_report
fc_seq_output_file moat370_log
fc_seq_output_file moat370_log2
fc_seq_output_file moat370_log3
fc_seq_output_file moat370_trace
fc_seq_output_file moat370_alert
fc_seq_output_file moat370_opatch
fc_seq_output_file moat370_driver

fc_clean_file_name "moat370_main_report"  "moat370_main_report_nopath"  "PATH"
fc_clean_file_name "moat370_zip_filename" "moat370_zip_filename_nopath" "PATH"

moat370_style_css="style_${exec_seq}.css"

# Enable database trace
if [ -z "${skip_trace}" ]
then
  fc_db_enable_trace
fi

## inclusion config determine skip flags
fc_set_value_var_decode moat370_skip_table   "${moat370_conf_incl_table}"   'N' "-" ''
fc_set_value_var_decode moat370_skip_csv     "${moat370_conf_incl_csv}"     'N' "-" ''
fc_set_value_var_decode moat370_skip_line    "${moat370_conf_incl_line}"    'N' "-" ''
fc_set_value_var_decode moat370_skip_pie     "${moat370_conf_incl_pie}"     'N' "-" ''
fc_set_value_var_decode moat370_skip_bar     "${moat370_conf_incl_bar}"     'N' "-" ''
fc_set_value_var_decode moat370_skip_graph   "${moat370_conf_incl_graph}"   'N' "-" ''
fc_set_value_var_decode moat370_skip_map     "${moat370_conf_incl_map}"     'N' "-" ''
fc_set_value_var_decode moat370_skip_treemap "${moat370_conf_incl_treemap}" 'N' "-" ''
fc_set_value_var_decode moat370_skip_text    "${moat370_conf_incl_text}"    'N' "-" ''
fc_set_value_var_decode moat370_skip_html    "${moat370_conf_incl_html}"    'N' "-" ''

## inclusion config determine skip flags
fc_set_value_var_decode moat370_def_skip_table   "${moat370_conf_def_table}"   'N' "-" ''
fc_set_value_var_decode moat370_def_skip_csv     "${moat370_conf_def_csv}"     'N' "-" ''
fc_set_value_var_decode moat370_def_skip_line    "${moat370_conf_def_line}"    'N' "-" ''
fc_set_value_var_decode moat370_def_skip_pie     "${moat370_conf_def_pie}"     'N' "-" ''
fc_set_value_var_decode moat370_def_skip_bar     "${moat370_conf_def_bar}"     'N' "-" ''
fc_set_value_var_decode moat370_def_skip_graph   "${moat370_conf_def_graph}"   'N' "-" ''
fc_set_value_var_decode moat370_def_skip_map     "${moat370_conf_def_map}"     'N' "-" ''
fc_set_value_var_decode moat370_def_skip_treemap "${moat370_conf_def_treemap}" 'N' "-" ''
fc_set_value_var_decode moat370_def_skip_text    "${moat370_conf_def_text}"    'N' "-" ''
fc_set_value_var_decode moat370_def_skip_html    "${moat370_conf_def_html}"    'N' "-" ''

fc_def_empty_var top_level_hints
##

## get cores_threads_hosts
if [ ${hosts_count} -eq 1 ]
then
  cores_threads_hosts="cores:${avg_core_count} threads:${avg_thread_count}"
else
  cores_threads_hosts="cores:${avg_core_count}(avg) threads:${avg_thread_count}(avg) hosts:${hosts_count}"
fi

tit_01=''
tit_02=''
tit_03=''
tit_04=''
tit_05=''
tit_06=''
tit_07=''
tit_08=''
tit_09=''
tit_10=''
tit_11=''
tit_12=''
tit_13=''
tit_14=''
tit_15=''

if [ -z ${history_days} ]
then
  history_days=0
fi

tool_sysdate=$(date '+%Y%m%d%H%M%S')
between_dates=", between ${moat370_date_from} and ${moat370_date_to}"

driver_seq=0
report_sequence=1
temp_seq=0
current_time=''

## Define Section Variables
fc_section_variables

## Print Database and License info only if it is a DB tool.
fc_def_empty_var db_lic_info
fc_def_empty_var db_ver_info
if [ "${moat370_sw_dbtool}" = 'Y' ]
then
  db_lic_info="Database:${database_name_short} License:${license_pack}."
  db_ver_info=" for DB ${db_version}"
fi

## main header

rm -f "${moat370_main_report}"
fc_paste_file_replacing_variables "${moat370_fdr_cfg}"/moat370_html_header.html "${moat370_main_report}"

moat370_time_stamp=$(date "${moat370_date_format}")
cat >> "${moat370_main_report}" <<EOF
<body>
<h1><em><a href="${moat370_sw_url}" target="_blank">${moat370_sw_name}</a></em> ${moat370_sw_vYYNN}: ${moat370_sw_title_desc}${db_ver_info}.</h1>

<pre>
${db_lic_info} This report covers the time interval between ${moat370_date_from} and ${moat370_date_to}. Days:${history_days}. Timestamp:${moat370_time_stamp}.
</pre>
EOF

unset db_lic_info
unset db_ver_info

## zip other files
if [ "${moat370_conf_sql_highlight}" = 'Y' ]
then
  fc_zip_file "${moat370_zip_filename}" "${moat370_fdr_js}/highlight.pack.js" false
  fc_zip_file "${moat370_zip_filename}" "${moat370_fdr_js}/vs.css" false
fi

if [ "${moat370_conf_sql_format}" = 'Y' ]
then
  fc_zip_file "${moat370_zip_filename}" "${moat370_fdr_js}/sql-formatter.js" false
fi

if [ "${moat370_conf_compress_html}" = 'ON' ]
then
  fc_zip_file "${moat370_zip_filename}" "${moat370_fdr_js}/gunzip.js" false
fi

fc_zip_file "${moat370_zip_filename}" "${moat370_sw_folder}/${moat370_sw_logo_fdr}/${moat370_sw_logo_file}" false
fc_zip_file "${moat370_zip_filename}" "${moat370_sw_folder}/${moat370_sw_logo_fdr}/${moat370_sw_icon_file}" false

if [ "${moat370_conf_compress_html}" = 'ON' -o -f ${enc_key_file}.enc ]
then
  fc_zip_file "${moat370_zip_filename}" "${moat370_fdr_js}/decode.min.js" false
fi

if [ -f "${enc_key_file}.enc" ]
then
  fc_zip_file "${moat370_zip_filename}" "${moat370_fdr_js}/aes.js" false
fi

fc_zip_file "${moat370_zip_filename}" "${enc_key_file}.enc"

cp "${moat370_fdr_js}/../LICENSE-3RD-PARTY" "${moat370_sw_output_fdr}/LICENSE-3RD-PARTY.txt" >> "${moat370_log3}"

if [ -f "${moat370_sw_folder}/LICENSE-3RD-PARTY" ]
then
  cat "${moat370_sw_folder}/LICENSE-3RD-PARTY" >> "${moat370_sw_output_fdr}/LICENSE-3RD-PARTY.txt"
fi

fc_zip_file "${moat370_zip_filename}" "${moat370_sw_output_fdr}/LICENSE-3RD-PARTY.txt"

cp "${moat370_fdr_js}/style.css" "${moat370_sw_output_fdr}/${moat370_style_css}" >> "${moat370_log3}"

fc_zip_file "${moat370_zip_filename}" "${moat370_sw_output_fdr}/${moat370_style_css}"

if [ "${moat370_conf_tablefilter}" = 'N' ]
then
  fc_zip_file "${moat370_zip_filename}" "${moat370_fdr_js}/sorttable.js" false
fi

##WHENEVER SQLERROR CONTINUE