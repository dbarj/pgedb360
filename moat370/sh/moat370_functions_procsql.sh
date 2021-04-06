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

fc_gen_select_star_query ()
{
  ## This code will generate a default "SELECT * FROM" query based on table of parameter 1 and put this query into parameter 2 variable.
  ## If parameter 3 is defined, it will order by this parameter. If param1 is a CDB view, con_id will be the first order by clause.
  local in_table="$1"
  local in_variable="$2"
  local v_insert_hint=''

  set +u
  local in_order_by="$3"
  fc_enable_set_u

  fc_set_value_var_nvl in_order_by "${in_order_by}" '1'

  local def_sel_star_qry=''

  v_in_table_upper=$(upper_var "${in_table}")
  v_transf=$(sed 's/^CDB_//' <<< "${v_in_table_upper}")
  fc_set_value_var_decode order_by_cdb_flag "${v_transf}" "${v_in_table_upper}" '' 'CON_ID, '

  in_order_by="${order_by_cdb_flag}${in_order_by}"

  if [ -n "${top_level_hints}" ]
  then
    v_insert_hint="/*+ ${top_level_hints} */ "
  fi

  def_sel_star_qry="
  SELECT ${v_insert_hint}/* ${section_id}.${report_sequence} */
         *
    FROM ${in_table}
   ORDER BY
         ${in_order_by}"

  eval ${in_variable}=\${def_sel_star_qry}

  unset order_by_cdb_flag
}

fc_exec_item ()
{
  local input_csv_mode=false
  local input_raw_mode=false

  ################################################
  ################################################

  ## Check Output Options

  local moat370_output_valid_opts='|table|csv|line|pie|bar|graph|map|treemap|text|html|'
  local output_item

  if [ -n "${output_type}" ]
  then
    for output_item in $(tr '|' ' ' <<< "${moat370_output_valid_opts}")
    do
      eval skip_${output_item}='--'
    done
  fi

  for output_item in $output_type
  do
    if [ $(instr_var "${moat370_output_valid_opts}" "|${output_item}|") -eq 0 ]
    then
      fc_echo_screen_log ""
      fc_echo_screen_log "Invalid output option \"${output_item}\". Valid options are: $(tr '|' ' ' <<< "${moat370_output_valid_opts}")".
      fc_reset_defaults
      return
    fi
    eval skip_${output_item}=''
  done

  if [ -z "${skip_text}" -o \
       -z "${skip_html}" ]
  then
    input_raw_mode=true
  fi

  if [ -z "${skip_table}" -o \
       -z "${skip_csv}" -o \
       -z "${skip_line}" -o \
       -z "${skip_pie}" -o \
       -z "${skip_bar}" -o \
       -z "${skip_graph}" -o \
       -z "${skip_map}" -o \
       -z "${skip_treemap}" ]
  then
    input_csv_mode=true
  fi

  ## Validate input parameters

  if ${input_csv_mode} && ${input_raw_mode}
  then
    fc_echo_screen_log ""
    fc_echo_screen_log "Invalid output option combination: ${output_type}".
    fc_reset_defaults
    return
  fi

  if [ -z "${sql_text}" -a \
       -z "${input_file}" ]
  then
    fc_echo_screen_log ""
    fc_echo_screen_log "Missing sql_text or input_file variables before calling fc_exec_item.".
    fc_reset_defaults
    return
  fi

  if [ -n "${sql_text}" -a \
       -n "${input_file}" ]
  then
    fc_echo_screen_log ""
    fc_echo_screen_log "sql_text and input_file both are defined. Please correct.".
    fc_reset_defaults
    return
  fi

  if [ -n "${sql_text}" -a \
      "${moat370_sw_db_type}" = "offline" ]
  then
    fc_echo_screen_log ""
    fc_echo_screen_log "Skipping sql_text item as moat370_sw_db_type is \"offline\".".
    fc_reset_defaults
    return
  fi

  if [ -z "${skip_text}" -a \
       -z "${skip_html}" ]
  then
    fc_echo_screen_log ""
    fc_echo_screen_log "Output can't be html and text at the same time.".
    fc_reset_defaults
    return
  fi

  ################################################
  ################################################

  # Run any database specific function before each topic.
  fc_db_pre_exec_call

  fc_clean_file_name "title" "title_no_spaces"
  spool_filename="${report_sequence}_${title_no_spaces}"

  ## log
  hh_mm_ss=$(get_time)
  fc_echo_screen_log ""
  fc_echo_screen_log division
  fc_echo_screen_log ""
  fc_echo_screen_log "${hh_mm_ss} ${section_id} ${section_name}"
  fc_echo_screen_log "${hh_mm_ss} ${title}${title_suffix}"
  fc_echo_screen_log ""

  # Remove both leading and trailing blank lines
  # http://sed.sourceforge.net/sed1line.txt / https://stackoverflow.com/questions/7359527/removing-trailing-starting-newlines-with-sed-awk-tr-and-friends
  sql_text=$($cmd_sed -e :a -e '/./,$!d;/^\n*$/{$d;N;};/\n$/ba' <<< "${sql_text}")

  [ -z "${sql_text}" ] && sql_show='N'

  ## When sql_show is NO, will print sql_text_display only if variable sql_text_display is forcelly specified.
  if [ "${sql_show}" = 'Y' ]
  then
    if [ -n "${sql_with_clause}" ]
    then
      sql_text_display="$(printf '%s\n%s' "${sql_with_clause}" "${sql_text}")"
    else
      sql_text_display="$(printf '%s' "${sql_text}")"
    fi
  fi

  ## Workarounds required for sql-formatter.js limitations (enabled when sql_format='Y')
  # Change Oracle double slash comments to comment blocks
  sql_text_display=$($cmd_sed 's/--\(.*\)/\/\*\1\*\//' <<< "${sql_text_display}")

  [ -n "${sql_text_display}" ] && ${input_csv_mode} && sql_text_display="${sql_text_display};"
  [ -n "${sql_text_display}" ] && fc_echo_screen_log "${sql_text_display}"

  ## Remove spaces before or after
  sql_text=$(trim_var "${sql_text}")

  # Not POSIX:
  # sql_text_display=$(fc_escape_markup_characters <(echo "${sql_text_display}"))
  fc_def_output_file sql_text_display_temp "sql_text_display_temp.sql"
  echo "${sql_text_display}" > "${sql_text_display_temp}"
  sql_text_display=$(fc_escape_markup_characters "${sql_text_display_temp}")
  rm -f "${sql_text_display_temp}"
  unset sql_text_display_temp

  fc_zip_file "${moat370_zip_filename}" "${moat370_log}" false

  ## spools query
  if ${input_csv_mode} && [ -n "${sql_text}" ]
  then
    fc_db_sql_transform "${sql_text}" > "${moat370_query}"
  elif ${input_raw_mode} && [ -n "${sql_text}" ]
  then
    echo "${sql_text}" > "${moat370_query}"
  fi

  ## update main report
  echo "<li title=\"${main_table}\">${title}" >> "${moat370_main_report}"

  fc_zip_file "${moat370_zip_filename}" "${moat370_main_report}" false

  ## Check SQL format and highlight
  fc_set_value_var_decode sql_hl     "${moat370_conf_sql_highlight}" 'N' 'N' "${sql_hl}"
  fc_set_value_var_decode sql_format "${moat370_conf_sql_format}"    'N' 'N' "${sql_format}"

  # If fc_exec_item is running for a SQL_TEXT
  fc_def_empty_var raw_spool_filename
  fc_def_empty_var csv_spool_filename

  ## get time t0
  get_time_t0=$(get_secs)

  if [ -n "${sql_text}" ]
  then
    if ${input_csv_mode}
    then
      fc_def_output_file csv_spool_filename "${spool_filename}.csv"
      fc_db_create_csv "${moat370_query}" "${csv_spool_filename}"
      if [ -f "${csv_spool_filename}" ] && \
      fc_db_check_file_sql_error "${csv_spool_filename}"
      then
        row_num=$(wc -l < "${csv_spool_filename}" | tr -d '[:space:]')
        [ $row_num -ne 0 ] && row_num=$(do_calc 'row_num-1') # Remove Header when there is something.
        ## If row_num is 0, return 0, otherwise subtract row_num_dif giving nothing less than a -1 result.
        if [ $row_num -ne 0 ]
        then
          row_num=$(do_calc 'row_num+row_num_dif')
          row_num=$(greatest_num "${row_num}" "-1")
        fi
      fi
      fc_echo_screen_log ""
      fc_echo_screen_log "${row_num} rows selected."
    elif ${input_raw_mode}
    then
      fc_def_output_file raw_spool_filename "${spool_filename}.txt"
      fc_db_create_raw "${moat370_query}" "${raw_spool_filename}"
      if [ -f "${raw_spool_filename}" ] && \
      fc_db_check_file_sql_error "${raw_spool_filename}"
      then
        row_num='?'
      fi
    fi
  else
    if ${input_csv_mode}
    then
      csv_spool_filename="${input_file}"
      if [ -f "${csv_spool_filename}" ]
      then
        row_num=$(wc -l < "${csv_spool_filename}" | tr -d '[:space:]')
        row_num=$(do_calc 'row_num-1') # Remove Header.
        ## If row_num is 0, return 0, otherwise subtract row_num_dif giving nothing less than a -1 result.
        if [ $row_num -ne 0 ]
        then
          row_num=$(do_calc 'row_num+row_num_dif')
          row_num=$(greatest_num "${row_num}" "-1")
        fi
      fi
      fc_echo_screen_log ""
      fc_echo_screen_log "${row_num} rows selected."
    elif ${input_raw_mode}
    then
      raw_spool_filename="${input_file}"
      if [ -f "${raw_spool_filename}" ]
      then
        row_num='?'
      fi
    fi
  fi

  ## get time t1
  get_time_t1=$(get_secs)

  hh_mm_ss=$(get_time)
  fc_echo_screen_log ""
  fc_echo_screen_log "${hh_mm_ss} ${section_id}.${report_sequence}"

  ## execute one sql
  [ -z "${skip_table}${moat370_skip_table}" ]     && fc_proc_one_table
  [ -z "${skip_csv}${moat370_skip_csv}" ]         && fc_proc_one_csv
  [ -z "${skip_line}${moat370_skip_line}" ]       && fc_proc_line_chart
  [ -z "${skip_pie}${moat370_skip_pie}" ]         && fc_proc_pie_chart
  [ -z "${skip_bar}${moat370_skip_bar}" ]         && fc_proc_bar_chart
  [ -z "${skip_graph}${moat370_skip_graph}" ]     && fc_proc_graphviz_chart
  [ -z "${skip_map}${moat370_skip_map}" ]         && fc_proc_map_chart
  [ -z "${skip_treemap}${moat370_skip_treemap}" ] && fc_proc_treemap_chart
  [ -z "${skip_text}${moat370_skip_text}" ]       && fc_proc_one_text_file
  [ -z "${skip_html}${moat370_skip_html}" ]       && fc_proc_one_html_file

  ## Check D3 Graphs
  local moat370_d3_graph_valid_opts='|circle_packing|'
  fc_def_empty_var moat370_d3_graph_skip
  fc_def_empty_var d3_graph

  set +u
  [ -z "${d3_graph}" ] && d3_graph=""
  set +u

  fc_def_empty_var moat370_skip_d3_graph
  [ -z "${d3_graph}" ] && moat370_skip_d3_graph='-'

  [ $(instr_var "${moat370_d3_graph_skip}" "|${d3_graph}|") -gt 0 ] && moat370_skip_d3_graph='-'
  [ $(instr_var "${moat370_d3_graph_valid_opts}" "|${d3_graph}|") -eq 0 ] && moat370_skip_d3_graph='-'

  [ -z "${moat370_skip_d3_graph}" ] && fc_proc_d3_${d3_graph}

  unset moat370_skip_d3_graph

  ##
  fc_zip_file "${moat370_zip_filename}" "${moat370_log2}" false
  fc_zip_file "${moat370_zip_filename}" "${moat370_log3}" false

  ## update main report
  [ "${row_num}" != '?' ] && echo "<small><em> (${row_num})</em></small>" >> "${moat370_main_report}"
  echo "</li>" >> "${moat370_main_report}"

  fc_zip_file "${moat370_zip_filename}" "${moat370_main_report}" false

  ## cleanup
  [ -f "${moat370_query}" ] && rm -f "${moat370_query}"
  if [ -n "${sql_text}" ]
  then
    [ -n "${csv_spool_filename}" ] && rm -f "${csv_spool_filename}"
    [ -n "${raw_spool_filename}" ] && rm -f "${raw_spool_filename}"
  fi
  fc_reset_defaults

  ##
  moat370_column_print='YES'
  moat370_section_print='YES'

  ## report sequence
  report_sequence=$(do_calc 'report_sequence+1')
}

fc_proc_one_table ()
{
  ## add seq to spool_filename
  local one_spool_filename="${spool_filename}"
  local one_spool_fullpath_filename

  [ ! -f "${csv_spool_filename}" ] && echo_error "Can't run fc_proc_one_table with provided inputs." && return

  fc_seq_output_file one_spool_filename
  fc_def_output_file one_spool_fullpath_filename "${one_spool_filename}.html"
  rm -f "${one_spool_fullpath_filename}"

  fc_html_topic_intro "${one_spool_filename}.html" table

  fc_csv_to_html_table "${csv_spool_filename}" "${one_spool_fullpath_filename}"

  fc_add_tablefilter "${one_spool_fullpath_filename}"
  fc_add_sorttable   "${one_spool_fullpath_filename}"

  ## footer
  [ -n "${foot}" ] && echo '<font class="n">Notes:<br>' >> "${one_spool_fullpath_filename}"
  [ -n "${foot}" ] && echo "1) ${foot}" >> "${one_spool_fullpath_filename}"
  [ -n "${foot}" ] && echo '</font>' >> "${one_spool_fullpath_filename}"

  fc_html_topic_end "${one_spool_fullpath_filename}" table '' "${sql_show}"

  fc_encode_html "${one_spool_fullpath_filename}"

  fc_zip_file "${moat370_zip_filename}" "${one_spool_fullpath_filename}"

  unset one_spool_fullpath_filename
}

fc_proc_one_text ()
{
  # https://stackoverflow.com/questions/10518207/tool-to-convert-csv-data-to-stackoverflow-friendly-text-only-table
  true
}

fc_proc_one_csv ()
{
  ## add seq to one_spool_filename
  local one_spool_filename="${spool_filename}"
  local one_spool_fullpath_filename

  fc_seq_output_file one_spool_filename
  fc_def_output_file one_spool_fullpath_filename "${one_spool_filename}.csv"
  rm -f "${one_spool_fullpath_filename}"

  ## display
  hh_mm_ss=$(get_time)
  fc_echo_screen_log "${hh_mm_ss} ${section_id} ${one_spool_filename}.csv"

  cat "${csv_spool_filename}" >> "${one_spool_fullpath_filename}"

  fc_convert_txt_to_html one_spool_fullpath_filename
  fc_encode_html "${one_spool_fullpath_filename}"

  # Reset one_spool_filename in case it was renamed by the functions above
  fc_clean_file_name one_spool_fullpath_filename one_spool_filename PATH

  ## update main report
  echo "<a href=\"${one_spool_filename}\">csv</a>" >> "${moat370_main_report}"

  total_hours="Topic execution time: $(convert_secs $(do_calc 'get_time_t1-get_time_t0'))."

  ## update log2
  fc_def_empty_var moat370_prev_sql_id
  fc_def_empty_var moat370_prev_child_number
  echo "$(date "${moat370_date_format}"), $(do_calc 'get_time_t1-get_time_t0')s, rows: ${row_num}, ${section_id}, ${main_table}, ${moat370_prev_sql_id}, ${moat370_prev_child_number}, ${title_no_spaces}, csv, ${one_spool_fullpath_filename}" >> "${moat370_log2}"

  fc_zip_file "${moat370_zip_filename}" "${one_spool_fullpath_filename}"

  unset one_spool_fullpath_filename
}

fc_proc_one_text_file ()
{
  local one_spool_filename
  local one_spool_fullpath_filename

  [ -z "${raw_spool_filename}" ] && echo_error "Can't run fc_proc_one_text_file with provided inputs." && return

  ## Check mandatory variables
  local one_spool_text_file="${raw_spool_filename}"
  fc_def_empty_var one_spool_text_file_type
  fc_def_empty_var one_spool_text_file_rename

  [ -n "${sql_text}" ] && one_spool_text_file_rename='Y' # Force rename if output comes from a SQL.

  [ "${one_spool_text_file_rename}" = 'Y' -a ! -f "${raw_spool_filename}" ] && echo_error "Can't run fc_proc_one_text_file with provided inputs." && return

  fc_set_value_var_nvl one_spool_text_file_type "${one_spool_text_file_type}" 'text'

  fc_clean_file_name one_spool_text_file one_spool_filename PATH
  fc_def_output_file one_spool_fullpath_filename "${one_spool_filename}"

  if [ "${one_spool_text_file_rename}" = 'Y' ]
  then
    fc_seq_output_file one_spool_fullpath_filename
    fc_clean_file_name one_spool_fullpath_filename one_spool_filename PATH
  fi

  ## display
  hh_mm_ss=$(get_time)
  fc_echo_screen_log "${hh_mm_ss} ${section_id} ${one_spool_filename}"

  ## Protect accidentally renaming files not in Output Folder.
  ## Check if one_spool_text_file is on Output Folder if renaming is enabled.
  one_spool_text_file_path=$($cmd_sed 's:/[^/]*$::g' <<< "${one_spool_text_file}")

  local one_spool_text_file_chk=false
  if [ "${one_spool_text_file_path}" = "${moat370_sw_output_fdr}" ]
  then
    one_spool_text_file_chk=true
  fi

  if [ "${one_spool_text_file_rename}" = 'Y' -a -f "${one_spool_text_file}" ] && ${one_spool_text_file_chk}
  then
    mv "${one_spool_text_file}" "${one_spool_fullpath_filename}"
  fi

  unset one_spool_text_file_chk

  # Disable rownum if one_spool_text_file_rename = N as target file may not be accessible.
  [ "${one_spool_text_file_rename}" = 'N' ] && row_num='?'
  #if [ -f "${one_spool_fullpath_filename}" ]
  #then
  #  row_num=$(cat "${one_spool_fullpath_filename}" | wc -l | tr -d '[:space:]')
  #else
  #  row_num='?'
  #fi

  if [ "${one_spool_text_file_rename}" = 'Y' ]
  then
    fc_convert_txt_to_html one_spool_fullpath_filename
    fc_encode_html "${one_spool_fullpath_filename}"
  fi

  ## Get one_spool_filename from one_spool_fullpath_filename in case it was renamed by functions above.
  fc_clean_file_name one_spool_fullpath_filename one_spool_filename PATH

  ## update main report
  echo "<a href=\"${one_spool_filename}\">${one_spool_text_file_type}</a>" >> "${moat370_main_report}"

  total_hours="Topic execution time: $(convert_secs $(do_calc 'get_time_t1-get_time_t0'))."

  ## update log2
  fc_def_empty_var moat370_prev_sql_id
  fc_def_empty_var moat370_prev_child_number
  echo "$(date "${moat370_date_format}"), $(do_calc 'get_time_t1-get_time_t0')s, rows: ${row_num}, ${section_id}, ${main_table}, ${moat370_prev_sql_id}, ${moat370_prev_child_number}, ${title_no_spaces}, txt, ${one_spool_fullpath_filename}" >> "${moat370_log2}"

  if [ "${one_spool_text_file_rename}" = 'Y' ]
  then
    fc_zip_file "${moat370_zip_filename}" "${one_spool_fullpath_filename}"
  fi

  unset one_spool_text_file one_spool_text_file_rename one_spool_text_file_type
  unset one_spool_fullpath_filename
}

fc_proc_one_html_file ()
{
  local one_spool_filename="${spool_filename}"
  local one_spool_fullpath_filename

  [ ! -f "${raw_spool_filename}" ] && echo_error "Can't run fc_proc_one_html_file with provided inputs." && return

  ## add seq to spool_filename
  fc_seq_output_file one_spool_filename
  fc_def_output_file one_spool_fullpath_filename "${one_spool_filename}.html"

  ## Check mandatory variables
  local one_spool_html_file="${input_file}"
  fc_def_empty_var one_spool_html_file_type
  fc_def_empty_var one_spool_html_desc_table
  fc_set_value_var_nvl 'one_spool_html_desc_table' "${one_spool_html_desc_table}" 'N'

  fc_set_value_var_nvl one_spool_html_file_type "${one_spool_html_file_type}" 'html'

  fc_html_topic_intro "${one_spool_filename}.html" ${one_spool_html_file_type}

  ## body
  cat "${raw_spool_filename}" >> "${one_spool_fullpath_filename}"

  # Move this to fc_exec_item

  # if grep -q '<tr>' "${raw_spool_filename}"
  # then
  #   row_num="$(($(grep '<tr>' "${raw_spool_filename}" | wc -l)-1))"
  # fi

  ## footer
  [ -n "${foot}" ] && echo '<font class="n">Notes:<br>' >> "${one_spool_fullpath_filename}"
  [ -n "${foot}" ] && echo "1) ${foot}" >> "${one_spool_fullpath_filename}"
  [ -n "${foot}" ] && echo '</font>' >> "${one_spool_fullpath_filename}"

  fc_html_topic_end "${one_spool_fullpath_filename}" ${one_spool_html_file_type} ${one_spool_html_desc_table} "${sql_show}"

  fc_encode_html "${one_spool_fullpath_filename}"

  ## zip
  fc_zip_file "${moat370_zip_filename}" "${one_spool_fullpath_filename}"

  unset one_spool_html_desc_table one_spool_html_file_type
}

fc_html_topic_intro ()
{
  ## Param1: file_name / Param2: Type
  local in_param1="$1"
  local in_param2="$2"

  fc_def_output_file one_spool_fullpath_filename "${in_param1}"

  ## display
  hh_mm_ss=$(get_time)
  fc_echo_screen_log "${hh_mm_ss} ${section_id} ${in_param1}"

  ## update main report
  echo "<a href=\"${in_param1}\">${in_param2}</a>" >> "${moat370_main_report}"

  ## header
  fc_paste_file_replacing_variables "${moat370_fdr_cfg}"/moat370_html_header.html "${one_spool_fullpath_filename}"

  ## javascripts
  [ "${sql_format}" = 'Y' ] && echo '<script type="text/javascript" src="sql-formatter.js"></script>' >> "${one_spool_fullpath_filename}"
  [ "${sql_hl}" = 'Y' ] && echo '<script type="text/javascript" src="highlight.pack.js"></script>' >> "${one_spool_fullpath_filename}"
  [ "${sql_hl}" = 'Y' ] && echo '<link rel="stylesheet" href="vs.css">' >> "${one_spool_fullpath_filename}"

  fc_def_empty_var main_table_print
  fc_set_value_var_nvl2 main_table_print "${main_table}" " <em>(${main_table})</em>" ''

  ## topic begin
  echo >> "${one_spool_fullpath_filename}"
  echo "<!-- ${in_param1} \$ -->" >> "${one_spool_fullpath_filename}"
  echo "</head>" >> "${one_spool_fullpath_filename}"
  echo "<body>" >> "${one_spool_fullpath_filename}"
  echo "<h1> <img src=\"${moat370_sw_logo_file}\" alt=\"${moat370_sw_name}\" height=\"46\" width=\"47\" /> ${section_id}.${report_sequence}. ${title}${title_suffix}${main_table_print}</h1>" >> "${one_spool_fullpath_filename}"
  echo "<!--BEGIN_SENSITIVE_DATA-->" >> "${one_spool_fullpath_filename}"
  echo "<br>" >> "${one_spool_fullpath_filename}"
  [ -n "${abstract}" ] && echo "${abstract}" >> "${one_spool_fullpath_filename}"
  echo >> "${one_spool_fullpath_filename}"

  unset main_table_print
}

fc_html_topic_end ()
{
  ## Param1: file_name
  ## Param2: Type
  ## Param3: Print Table (Default Y)
  ## Param4: Print SQL (Default Y)

  local one_spool_fullpath_filename="$1"
  local in_param2="$2"

  set +u
  local in_param3="$3"
  local in_param4="$4"
  fc_enable_set_u

  fc_set_value_var_nvl 'in_param3' "${in_param3}" 'Y'
  fc_set_value_var_nvl 'in_param4' "${in_param4}" 'Y'

  echo "<pre>" >> "${one_spool_fullpath_filename}"

  [ "${in_param3}" = 'Y' -a -n "${main_table}" ] && fc_db_table_description "${one_spool_fullpath_filename}"

  echo '<code class="sql" id="SQL_Query">' >> "${one_spool_fullpath_filename}"

  [ "${sql_format}" = 'N' -a "${in_param4}" = 'Y' ] && echo "${sql_text_display}" >> "${one_spool_fullpath_filename}"

  echo "</code>" >> "${one_spool_fullpath_filename}"

  [ "${in_param4}" = 'Y' ] && echo "${row_num} rows selected." >> "${one_spool_fullpath_filename}"

  echo "</pre>" >> "${one_spool_fullpath_filename}"

  echo '<script type="text/javascript" id="sqlfor_script">' > "${one_spool_fullpath_filename}.tmp"
  echo 'document.getElementById("SQL_Query").innerHTML = window.sqlFormatter.format(" " +' >> "${one_spool_fullpath_filename}.tmp"

  sed 's/"/\\"/g; s/^/"/g; s/$/ " +/g' <<< "${sql_text_display}" >> "${one_spool_fullpath_filename}.tmp"

  echo '" ");' >> "${one_spool_fullpath_filename}.tmp"
  echo "</script>" >> "${one_spool_fullpath_filename}.tmp"

  [ "${sql_format}" = 'Y' -a "${in_param4}" = 'Y' ] && cat "${one_spool_fullpath_filename}.tmp" >> "${one_spool_fullpath_filename}"

  echo '<script type="text/javascript" id="sqlhl_script">hljs.initHighlighting();</script>' > "${one_spool_fullpath_filename}.tmp"

  [ "${sql_hl}" = 'Y' -a "${in_param4}" = 'Y' ] && cat "${one_spool_fullpath_filename}.tmp" >> "${one_spool_fullpath_filename}"

  rm -f "${one_spool_fullpath_filename}.tmp"

  echo "<!--END_SENSITIVE_DATA-->" >> "${one_spool_fullpath_filename}"

  total_hours="Topic execution time: $(convert_secs $(do_calc 'get_time_t1-get_time_t0'))."

  moat370_time_stamp=$(date "${moat370_date_format}")
  fc_paste_file_replacing_variables "${moat370_fdr_cfg}"/moat370_html_footer.html "${one_spool_fullpath_filename}"

  ## update log2
  fc_def_empty_var moat370_prev_sql_id
  fc_def_empty_var moat370_prev_child_number
  echo "$(date "${moat370_date_format}"), $(do_calc 'get_time_t1-get_time_t0')s, rows: ${row_num}, ${section_id}, ${main_table}, ${moat370_prev_sql_id}, ${moat370_prev_child_number}, ${title_no_spaces}, ${in_param2} , ${one_spool_fullpath_filename}" >> "${moat370_log2}"

}

fc_add_tablefilter ()
{
  ## Parameter 1 : HTML file to have tag fixed
  local in_html_src_file="$1"
  ##

  fc_def_empty_var filtertab_option1
  fc_def_empty_var filtertab_option2
  fc_def_empty_var filtertab_option3
  fc_def_empty_var filtertab_option4

  fc_set_value_var_nvl 'filtertab_option1' "${filtertab_option1}" "alternate_rows: true, col_types: ['number'],"
  fc_set_value_var_nvl 'filtertab_option2' "${filtertab_option2}" "rows_counter: true, btn_reset: true, loader: true,"
  fc_set_value_var_nvl 'filtertab_option3' "${filtertab_option3}" "status_bar: true, mark_active_columns: true, highlight_keywords: true,"
  fc_set_value_var_nvl 'filtertab_option4' "${filtertab_option4}" "auto_filter: true, extensions:[{ name: 'sort' }]"

  ## Add <thead> to first row so column sort can work.
  fc_add_thead_tag_html "${in_html_src_file}" && ret=$? || ret=$?
  [ $ret -ne 0 ] && return 0 # If it fails to add the thead (maybe no rows = no header), stop here.

  ## Filter TABLE

  echo "#: click on a column heading to sort on it" >> "${in_html_src_file}"
  echo '<br>' >> "${in_html_src_file}"
  echo '<script id="tablefilter" type="text/javascript" src="tablefilter/tablefilter.js"></script>' >> "${in_html_src_file}"
  echo '<script id="tablefilter-cfg" data-config>' >> "${in_html_src_file}"
  echo "    var filtersConfig = {" >> "${in_html_src_file}"
  echo "        base_path: 'tablefilter/'," >> "${in_html_src_file}"
  echo "        ${filtertab_option1}" >> "${in_html_src_file}"
  echo "        ${filtertab_option2}" >> "${in_html_src_file}"
  echo "        ${filtertab_option3}" >> "${in_html_src_file}"
  echo "        ${filtertab_option4}" >> "${in_html_src_file}"
  echo "    };" >> "${in_html_src_file}"
  echo "" >> "${in_html_src_file}"
  echo "    var tf = new TableFilter('maintable', filtersConfig);" >> "${in_html_src_file}"
  echo "    tf.init();" >> "${in_html_src_file}"
  echo "" >> "${in_html_src_file}"
  echo "</script>" >> "${in_html_src_file}"

  unset filtertab_option1 filtertab_option2 filtertab_option3 filtertab_option4

  moat370_tf_usage='Y'
  ##
}

fc_add_thead_tag_html ()
{
  local in_file="$1"
  local out_file="$1.tmp"

  test -f "${in_file}" || return 1

  in_fst_tr_line=`$cmd_sed -ne '/<tr>/=' "${in_file}" | $cmd_sed -n 1p`
  in_sec_tr_line=`$cmd_sed -ne '/<\/tr>/=' "${in_file}" | $cmd_sed -n 1p`
  in_last_line=`cat "${in_file}" | wc -l`

  test -n "${in_fst_tr_line}" || return 1
  test -n "${in_sec_tr_line}" || return 1
  test -n "${in_last_line}"   || return 1

  $cmd_awk "NR >= 1 && NR < $in_fst_tr_line {print;}" "${in_file}" > "${out_file}"
  echo '<thead>' >> "${out_file}"
  $cmd_awk "NR >= $in_fst_tr_line && NR <= $in_sec_tr_line {print;}" "${in_file}" >> "${out_file}"
  echo '</thead>' >> "${out_file}"
  $cmd_awk "NR > $in_sec_tr_line && NR <= $in_last_line {print;}" "${in_file}" >> "${out_file}"
  mv "${out_file}" "${in_file}"

  ###
}

fc_add_sorttable ()
{
  ## Parameter 1 : HTML file to have tag fixed
  local in_html_src_file="$1"
  ##

  ## Sort TABLE
  echo "#: click on a column heading to sort on it" >> "${in_html_src_file}"
  echo '<br>' >> "${in_html_src_file}"
  echo '<script type="text/javascript" src="sorttable.js"></script>' >> "${in_html_src_file}"

  moat370_tf_usage='N'
  ##
}
