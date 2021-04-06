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

fc_csv_to_html_table ()
{
  # This code will convert a CSV to HTML
  # CSV must have fields optionally enclosed by " and separated by ,

  local v_sourcecsv="$1"
  local v_out_html="$2"

  test -f "${v_sourcecsv}" || return 1

  echo "<p>" >> "${v_out_html}"
  echo '<table id="maintable" class="sortable">' >> "${v_out_html}"

  local v_fcol_tag_o='<th scope="col">'
  local v_fcol_tag_c="</th>"
  local v_acol_tag_o="<td>"
  local v_acol_tag_c="</td>"
  local v_line_o="<tr>"
  local v_line_c="</tr>"

  local step_source=''
  if grep -q '<' "${v_sourcecsv}" || grep -q '>' "${v_sourcecsv}"
  then
    fc_def_output_file step_source 'step_source.csv'
    rm -f "${step_source}"
    fc_escape_markup_characters "${v_sourcecsv}" > "${step_source}"
    v_sourcecsv="${step_source}"
  fi

  # 1st Line

  head -n 1 "${v_sourcecsv}" | \
  ${cmd_awk_csv} -v outsep="${v_fcol_tag_c}${v_fcol_tag_o}" --source '{csv_parse_and_display($0, separator, enclosure, outsep)}' > "${v_out_html}.tmp"
  ${cmd_awk} -v prefix="${v_line_o}${v_fcol_tag_o}" -v suffix="${v_fcol_tag_c}${v_line_c}" '{print prefix $0 suffix}' "${v_out_html}.tmp" > "${v_out_html}.tmp.2"

  mv "${v_out_html}.tmp.2" "${v_out_html}.tmp"
  cat "${v_out_html}.tmp" >> "${v_out_html}"

  # All Lines

  ${cmd_awk_csv} -v outsep="${v_acol_tag_c}${v_acol_tag_o}" --source '{csv_parse_and_display($0, separator, enclosure, outsep)}' "${v_sourcecsv}" > "${v_out_html}.tmp"
  ${cmd_awk} -v prefix="${v_line_o}${v_acol_tag_o}" -v suffix="${v_acol_tag_c}${v_line_c}" '{print prefix $0 suffix}' "${v_out_html}.tmp" > "${v_out_html}.tmp.2"

  mv "${v_out_html}.tmp.2" "${v_out_html}.tmp"
  ${cmd_sed} '1d' "${v_out_html}.tmp" >> "${v_out_html}"

  [ -n "${step_source}" ] && rm -f "${step_source}"

  rm -f "${v_out_html}.tmp"

  ############################################################

  echo "</table>" >> "${v_out_html}"
  echo "<p>" >> "${v_out_html}"

}

fc_csv_to_gchart_vector ()
{
  # This code will convert a CSV to GCHART vector.
  # Please note all fields will be included, as is, on the GCHART vector.

  if [ $# -ne 2 ]
  then
    echo_error "Two arguments are needed..."
    return 1
  fi

  local v_sep="$1"
  local v_sourcecsv="$2"
  local v_out_file="$2.tmp"

  local cmd_awk_param="-f ${cmd_awk_awk_func_dir} -v separator=${v_sep} -v enclosure=\""
  local cmd_awk_csv="${cmd_gawk} ${cmd_awk_param}"

  test -f "$v_sourcecsv" || return 1

  local v_fcol_tag_o="'"
  local v_fcol_tag_c="'"
  local v_acol_tag_o=""
  local v_acol_tag_c=""
  local v_col_sep=","
  local v_line_o="["
  local v_line_c="]"
  local v_line_sep=","

  # 1st Line

  head -n 1 "${v_sourcecsv}" | \
  ${cmd_awk_csv} -v outsep="${v_fcol_tag_c}${v_col_sep}${v_fcol_tag_o}" --source '{csv_parse_and_display($0, separator, enclosure, outsep)}' > "${v_out_file}"
  ${cmd_awk} -v prefix="${v_line_o}${v_fcol_tag_o}" -v suffix="${v_fcol_tag_c}${v_line_c}" '{print prefix $0 suffix}' "${v_out_file}" > "${v_out_file}.2"

  mv "${v_out_file}.2" "${v_out_file}"

  # All Lines

  ${cmd_awk_csv} -v outsep="${v_acol_tag_c}${v_col_sep}${v_acol_tag_o}" --source '{csv_parse_and_display($0, separator, enclosure, outsep)}' "${v_sourcecsv}" > "${v_out_file}.2"
  ${cmd_awk} -v prefix="${v_line_o}${v_acol_tag_o}" -v suffix="${v_acol_tag_c}${v_line_c}" '{print prefix $0 suffix}' "${v_out_file}.2" > "${v_out_file}.3"

  mv "${v_out_file}.3" "${v_out_file}.2"
  ${cmd_sed} '1d' "${v_out_file}.2" >> "${v_out_file}"
  ${cmd_sed} '$!s/$/,/' "${v_out_file}" > "${v_out_file}.2"
  mv "${v_out_file}.2" "${v_out_file}"

  cat "${v_out_file}"

  rm -f "${v_out_file}"
  return 0
}

fc_csv_keep_until_column ()
{
  # This code will truncate the CSV until the column specified.
  if [ $# -ne 3 ]
  then
    echo_error "$0: Three arguments are needed.. given: $#"
    return 1
  fi

  local v_infile="$1"
  local v_outfile="$2"
  local v_last_field="$3"
  ###

  # Other scripts depends on this file created
  touch "${v_outfile}"

  if [ ! -s "${v_infile}" ]
  then
    echo_error "${v_infile} is zero sized."
    return 1
  fi

  # "${v_outfile}.2" is used in case input and output are the same.
  ${cmd_awk_csv} --source '{csv_print_until_field_record($0, separator, enclosure, '${v_last_field}')}' "${v_infile}" > "${v_outfile}.2"
  mv "${v_outfile}.2" "${v_outfile}"
  #####
}

fc_csv_remove_column ()
{
  # This code will remove from the CSV the column specified.
  if [ $# -ne 3 ]
  then
    echo_error "$0: Three arguments are needed.. given: $#"
    return 1
  fi

  local v_infile="$1"
  local v_outfile="$2"
  local v_col_remove="$3"
  ###

  # Other scripts depends on this file created
  touch "${v_outfile}"

  if [ ! -s "${v_infile}" ]
  then
    echo_error "${v_infile} is zero sized."
    return 1
  fi

  # "${v_outfile}.2" is used in case input and output are the same.
  ${cmd_awk_csv} --source '{csv_print_skip_field_record($0, separator, enclosure, '${v_col_remove}')}' "${v_infile}" > "${v_outfile}.2"
  mv "${v_outfile}.2" "${v_outfile}"
  #####
}

fc_enquote_column_single_quote ()
{
  # This code will add single quotes to the given column.
  # This function will also remove all the default quotes from the columns.
  if [ $# -ne 3 ]
  then
    echo_error "$0: Three arguments are needed.. given: $#"
    return 1
  fi

  local v_infile="$1"
  local v_outfile="$2"
  local v_col_enquote="$3"
  ###

  # Other scripts depends on this file created
  touch "${v_outfile}"

  if [ ! -s "${v_infile}" ]
  then
    echo_error "${v_infile} is zero sized."
    return 1
  fi

  # "${v_outfile}.2" is used in case input and output are the same.
  ${cmd_awk_csv} -v enquote="'" --source '{csv_print_enquote_field($0, separator, enclosure, '${v_col_enquote}', enquote )}' "${v_infile}" > "${v_outfile}.2"
  mv "${v_outfile}.2" "${v_outfile}"
  #####
}

fc_remove_column_enclosure ()
{
  # This code will remove the enclosure for the given column, if it has one.
  if [ $# -ne 3 ]
  then
    echo_error "$0: Three arguments are needed.. given: $#"
    return 1
  fi

  local v_infile="$1"
  local v_outfile="$2"
  local v_col_rem_enclosure="$3"
  ###

  # Other scripts depends on this file created
  touch "${v_outfile}"

  if [ ! -s "${v_infile}" ]
  then
    echo_error "${v_infile} is zero sized."
    return 1
  fi

  # "${v_outfile}.2" is used in case input and output are the same.
  ${cmd_awk_csv} --source '{csv_print_rem_enclosure_field($0, separator, enclosure, '${v_col_rem_enclosure}')}' "${v_infile}" > "${v_outfile}.2"
  mv "${v_outfile}.2" "${v_outfile}"
  #####
}