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

fc_proc_line_chart ()
{
  ## add seq to one_spool_filename
  local one_spool_filename="${spool_filename}"
  local one_spool_fullpath_filename

  [ ! -f "${csv_spool_filename}" ] && echo_error "Can't run fc_proc_line_chart with provided inputs." && return
  [ ! -s "${csv_spool_filename}" ] && echo_time "CSV input is empty." && return

  fc_seq_output_file one_spool_filename
  fc_def_output_file one_spool_fullpath_filename "${one_spool_filename}_line_chart.html"
  rm -f "${one_spool_fullpath_filename}"

  ## Check mandatory variables
  fc_def_empty_var tit_01
  fc_def_empty_var tit_02
  fc_def_empty_var tit_03
  fc_def_empty_var tit_04
  fc_def_empty_var tit_05
  fc_def_empty_var tit_06
  fc_def_empty_var tit_07
  fc_def_empty_var tit_08
  fc_def_empty_var tit_09
  fc_def_empty_var tit_10
  fc_def_empty_var tit_11
  fc_def_empty_var tit_12
  fc_def_empty_var tit_13
  fc_def_empty_var tit_14
  fc_def_empty_var tit_15

  fc_def_empty_var stacked
  fc_def_empty_var haxis
  fc_def_empty_var vaxis
  fc_def_empty_var vbaseline
  fc_def_empty_var chartype

  fc_html_topic_intro "${one_spool_filename}_line_chart.html" line

  echo "<script type=\"text/javascript\" src=\"${moat370_sw_gchart_path}\"></script>" >> "${one_spool_fullpath_filename}"

  ## chart header
  echo '    <script type="text/javascript" id="gchart_script">' >> "${one_spool_fullpath_filename}"
  echo '      google.charts.load("current", {packages:["corechart"]});' >> "${one_spool_fullpath_filename}"
  echo '      google.charts.setOnLoadCallback(drawChart);' >> "${one_spool_fullpath_filename}"
  echo '      function drawChart() {' >> "${one_spool_fullpath_filename}"
  echo '        var data = google.visualization.arrayToDataTable([' >> "${one_spool_fullpath_filename}"

  # fc_csv_to_gchart_table "${csv_spool_filename}" "${one_spool_fullpath_filename}"

  local l_snap_id l_begin_time l_end_time l_line

  ## body
  local v_last_field=0
  local v_stop=0

  l_line='Date'
  [ -n "${tit_01}" ] && l_line="${l_line},${tit_01}" && v_last_field=5
  [ -n "${tit_02}" ] && l_line="${l_line},${tit_02}" && v_last_field=6
  [ -n "${tit_03}" ] && l_line="${l_line},${tit_03}" && v_last_field=7
  [ -n "${tit_04}" ] && l_line="${l_line},${tit_04}" && v_last_field=8
  [ -n "${tit_05}" ] && l_line="${l_line},${tit_05}" && v_last_field=9
  [ -n "${tit_06}" ] && l_line="${l_line},${tit_06}" && v_last_field=10
  [ -n "${tit_07}" ] && l_line="${l_line},${tit_07}" && v_last_field=11
  [ -n "${tit_08}" ] && l_line="${l_line},${tit_08}" && v_last_field=12
  [ -n "${tit_09}" ] && l_line="${l_line},${tit_09}" && v_last_field=13
  [ -n "${tit_10}" ] && l_line="${l_line},${tit_10}" && v_last_field=14
  [ -n "${tit_11}" ] && l_line="${l_line},${tit_11}" && v_last_field=15
  [ -n "${tit_12}" ] && l_line="${l_line},${tit_12}" && v_last_field=16
  [ -n "${tit_13}" ] && l_line="${l_line},${tit_13}" && v_last_field=17
  [ -n "${tit_14}" ] && l_line="${l_line},${tit_14}" && v_last_field=18
  [ -n "${tit_15}" ] && l_line="${l_line},${tit_15}" && v_last_field=19

  [ ${v_last_field} -eq 0 ] && echo_error "No line title defined." && return

  if [ -z "${input_file}" ]
  then
    fc_csv_keep_until_column "${csv_spool_filename}" "${csv_spool_filename}.2" ${v_last_field}
    fc_csv_remove_column "${csv_spool_filename}.2" "${csv_spool_filename}.2" 3 # begin_time
    fc_csv_remove_column "${csv_spool_filename}.2" "${csv_spool_filename}.2" 2 # snap_id
    fc_csv_remove_column "${csv_spool_filename}.2" "${csv_spool_filename}.2" 1 # row_number
  else
    cp "${csv_spool_filename}" "${csv_spool_filename}.2"
  fi
  ${cmd_sed} '1d' "${csv_spool_filename}.2" > "${csv_spool_filename}.3"
  
  fc_remove_column_enclosure "${csv_spool_filename}.3" "${csv_spool_filename}.3" 1

  ${cmd_awk} '
  { print "new Date("substr($0,1,4)"," \
                      substr($0,6,2)-1"," \
                      substr($0,9,2)"," \
                      substr($0,12,2)"," \
                      substr($0,15,2)"," \
                      substr($0,18,2)")" \
                      substr($0,20)}' "${csv_spool_filename}.3" > "${csv_spool_filename}.2"

  (echo "${l_line}" && cat "${csv_spool_filename}.2") > "${csv_spool_filename}.3"

  fc_csv_to_gchart_vector ',' "${csv_spool_filename}.3" > "${csv_spool_filename}.2"

  cat "${csv_spool_filename}.2" >> "${one_spool_fullpath_filename}"

  rm -f "${csv_spool_filename}.2" "${csv_spool_filename}.3"
 
  ## chart footer
  echo "        ]);" >> "${one_spool_fullpath_filename}"
  echo "        " >> "${one_spool_fullpath_filename}"
  echo "        var options = {${stacked}" >> "${one_spool_fullpath_filename}"
  echo "          backgroundColor: {fill: '#fcfcf0', stroke: '#336699', strokeWidth: 1}," >> "${one_spool_fullpath_filename}"
  echo "          explorer: {actions: ['dragToZoom', 'rightClickToReset'], maxZoomIn: 0.1}," >> "${one_spool_fullpath_filename}"
  echo "          title: '${title}${title_suffix}'," >> "${one_spool_fullpath_filename}"
  echo "          titleTextStyle: {fontSize: 16, bold: false}," >> "${one_spool_fullpath_filename}"
  echo "          focusTarget: 'category'," >> "${one_spool_fullpath_filename}"
  echo "          legend: {position: 'right', textStyle: {fontSize: 12}}," >> "${one_spool_fullpath_filename}"
  echo "          tooltip: {textStyle: {fontSize: 10}}," >> "${one_spool_fullpath_filename}"
  echo "          hAxis: {title: '${haxis}', gridlines: {count: -1}}," >> "${one_spool_fullpath_filename}"
  echo "          vAxis: {title: '${vaxis}', ${vbaseline} gridlines: {count: -1}}" >> "${one_spool_fullpath_filename}"
  echo "        };" >> "${one_spool_fullpath_filename}"
  echo "" >> "${one_spool_fullpath_filename}"
  echo "        var chart = new google.visualization.${chartype}(document.getElementById('chart_div'));" >> "${one_spool_fullpath_filename}"
  echo "        chart.draw(data, options);" >> "${one_spool_fullpath_filename}"
  echo "      }" >> "${one_spool_fullpath_filename}"
  echo "    </script>" >> "${one_spool_fullpath_filename}"
  echo >> "${one_spool_fullpath_filename}"
  echo '    <div id="chart_div" class="google-chart"></div>' >> "${one_spool_fullpath_filename}"
  echo >> "${one_spool_fullpath_filename}"

  ## footer
  echo '<font class="n">Notes:<br>' >> "${one_spool_fullpath_filename}"
  echo '1) Drag to zoom, and right click to reset<br>' >> "${one_spool_fullpath_filename}"
  echo "2) Up to ${history_days} days of history were considered" >> "${one_spool_fullpath_filename}"
  [ -n "${foot}" ] && echo "<br>3) ${foot}" >> "${one_spool_fullpath_filename}"
  echo '</font>' >> "${one_spool_fullpath_filename}"

  fc_set_value_var_nvl2 exec_sql_print "${input_file}" 'N' 'Y'
  fc_set_value_var_decode exec_sql_print "${sql_show}" 'N' 'N' "${exec_sql_print}"

  fc_html_topic_end "${one_spool_fullpath_filename}" line ${exec_sql_print} ${exec_sql_print}

  unset exec_sql_print

  fc_encode_html "${one_spool_fullpath_filename}"

  fc_zip_file "${moat370_zip_filename}" "${one_spool_fullpath_filename}"

  unset tit_01 tit_02 tit_03 tit_04 tit_05 tit_06 tit_07 tit_08 tit_09 tit_10 tit_11 tit_12 tit_13 tit_14 tit_15
  unset stacked haxis vaxis vbaseline chartype

  unset one_spool_fullpath_filename
}

fc_proc_pie_chart ()
{
  ## add seq to one_spool_filename
  local one_spool_filename="${spool_filename}"
  local one_spool_fullpath_filename

  [ ! -f "${csv_spool_filename}" ] && echo_error "Can't run fc_proc_pie_chart with provided inputs." && return
  [ ! -s "${csv_spool_filename}" ] && echo_time "CSV input is empty." && return

  fc_seq_output_file one_spool_filename
  fc_def_output_file one_spool_fullpath_filename "${one_spool_filename}_pie_chart.html"
  rm -f "${one_spool_fullpath_filename}"

  fc_html_topic_intro "${one_spool_filename}_pie_chart.html" pie

  echo "<script type=\"text/javascript\" src=\"${moat370_sw_gchart_path}\"></script>" >> "${one_spool_fullpath_filename}"

  ## chart header
  echo '    <script type="text/javascript" id="gchart_script">' >> "${one_spool_fullpath_filename}"
  echo '      google.charts.load("current", {packages:["corechart"]});' >> "${one_spool_fullpath_filename}"
  echo '      google.charts.setOnLoadCallback(drawChart);' >> "${one_spool_fullpath_filename}"
  echo '      function drawChart() {' >> "${one_spool_fullpath_filename}"
  echo '        var data = google.visualization.arrayToDataTable([' >> "${one_spool_fullpath_filename}"

  l_line='Slice,Value'

  if [ -z "${input_file}" ]
  then
    fc_csv_keep_until_column "${csv_spool_filename}" "${csv_spool_filename}.2" 3
    fc_csv_remove_column "${csv_spool_filename}.2" "${csv_spool_filename}.2" 1 # row_number
  else
    cp "${csv_spool_filename}" "${csv_spool_filename}.2"
  fi

  fc_enquote_column_single_quote "${csv_spool_filename}.2" "${csv_spool_filename}.2" 1

  ${cmd_sed} '1d' "${csv_spool_filename}.2" > "${csv_spool_filename}.3"

  (echo "${l_line}]" && cat "${csv_spool_filename}.3") > "${csv_spool_filename}.2"
  fc_csv_to_gchart_vector ',' "${csv_spool_filename}.2" > "${csv_spool_filename}.3"

  cat "${csv_spool_filename}.3" >> "${one_spool_fullpath_filename}"
  rm -f "${csv_spool_filename}.2" "${csv_spool_filename}.3"

  ## chart footer
  echo "        ]);" >> "${one_spool_fullpath_filename}"
  echo "        " >> "${one_spool_fullpath_filename}"
  echo "        var options = {" >> "${one_spool_fullpath_filename}"
  echo "          is3D: true," >> "${one_spool_fullpath_filename}"
  echo "          backgroundColor: {fill: '#fcfcf0', stroke: '#336699', strokeWidth: 1}," >> "${one_spool_fullpath_filename}"
  echo "          title: \"${title}${title_suffix}\"," >> "${one_spool_fullpath_filename}"
  echo "          titleTextStyle: {fontSize: 16, bold: false}," >> "${one_spool_fullpath_filename}"
  echo "          legend: {position: 'right', textStyle: {fontSize: 12}}," >> "${one_spool_fullpath_filename}"
  echo "          tooltip: {textStyle: {fontSize: 14}}," >> "${one_spool_fullpath_filename}"
  echo "          sliceVisibilityThreshold: 1/10000," >> "${one_spool_fullpath_filename}"
  echo "          pieSliceText: 'percentage'," >> "${one_spool_fullpath_filename}"
  echo "          tooltip: {" >> "${one_spool_fullpath_filename}"
  echo "                    showColorCode: true," >> "${one_spool_fullpath_filename}"
  echo "                    text: 'both'," >> "${one_spool_fullpath_filename}"
  echo "                    trigger: 'focus'" >> "${one_spool_fullpath_filename}"
  echo "                  }" >> "${one_spool_fullpath_filename}"
  echo "          };" >> "${one_spool_fullpath_filename}"
  echo "" >> "${one_spool_fullpath_filename}"
  echo "        var chart = new google.visualization.PieChart(document.getElementById('piechart_3d'));" >> "${one_spool_fullpath_filename}"
  echo "        chart.draw(data, options);" >> "${one_spool_fullpath_filename}"
  echo "      }" >> "${one_spool_fullpath_filename}"
  echo "    </script>" >> "${one_spool_fullpath_filename}"
  echo "" >> "${one_spool_fullpath_filename}"
  echo '    <div id="piechart_3d" class="google-chart"></div>' >> "${one_spool_fullpath_filename}"
  echo "" >> "${one_spool_fullpath_filename}"

  ## footer
  [ -n "${foot}" ] && echo '<font class="n">Notes:<br>' >> "${one_spool_fullpath_filename}"
  [ -n "${foot}" ] && echo "1) ${foot}" >> "${one_spool_fullpath_filename}"
  [ -n "${foot}" ] && echo '</font>' >> "${one_spool_fullpath_filename}"

  fc_set_value_var_nvl2 exec_sql_print "${input_file}" 'N' 'Y'
  fc_set_value_var_decode exec_sql_print "${sql_show}" 'N' 'N' "${exec_sql_print}"

  fc_html_topic_end "${one_spool_fullpath_filename}" pie ${exec_sql_print} ${exec_sql_print}

  unset exec_sql_print

  fc_encode_html "${one_spool_fullpath_filename}"

  fc_zip_file "${moat370_zip_filename}" "${one_spool_fullpath_filename}"

  unset one_spool_fullpath_filename
}

fc_proc_bar_chart ()
{
  ## add seq to one_spool_filename
  local one_spool_filename="${spool_filename}"
  local one_spool_fullpath_filename

  [ ! -f "${csv_spool_filename}" ] && echo_error "Can't run fc_proc_bar_chart with provided inputs." && return
  [ ! -s "${csv_spool_filename}" ] && echo_time "CSV input is empty." && return

  fc_seq_output_file one_spool_filename
  fc_def_output_file one_spool_fullpath_filename "${one_spool_filename}_bar_chart.html"

  ## Define bar_height and set value if unset
  fc_def_empty_var bar_height
  fc_set_value_var_nvl 'bar_height' "${bar_height}" '65%'

  fc_def_empty_var bar_minperc
  fc_set_value_var_nvl 'bar_minperc' "${bar_minperc}" '0'

  ## Define options
  fc_def_empty_var chart_option

  fc_set_value_var_nvl 'chart_option' "${chart_option}" \
  "chartArea: {left:90, top:90, width:'85%', height:\"${bar_height}\"},
   backgroundColor: {fill: 'white', stroke: '#336699', strokeWidth: 1},
   title: \"${section_id}.${report_sequence}. ${title}${title_suffix}\",
   titleTextStyle: {fontSize: 18, bold: false},
   legend: {position: 'none'},
   vAxis: {minValue: 0, title: \"${vaxis}\", titleTextStyle: {fontSize: 16, bold: false}},
   hAxis: {title: \"${haxis}\", titleTextStyle: {fontSize: 16, bold: false}},
   tooltip: {textStyle: {fontSize: 14}}"

  fc_html_topic_intro "${one_spool_filename}_bar_chart.html" bar

  echo "<script type=\"text/javascript\" src=\"${moat370_sw_gchart_path}\"></script>" >> "${one_spool_fullpath_filename}"

  ## chart header
  echo '    <script type="text/javascript" id="gchart_script">' >> "${one_spool_fullpath_filename}"
  echo '      google.charts.load("current", {packages:["corechart"]});' >> "${one_spool_fullpath_filename}"
  echo '      google.charts.setOnLoadCallback(drawChart);' >> "${one_spool_fullpath_filename}"
  echo '      function drawChart() {' >> "${one_spool_fullpath_filename}"
  echo '        var data = google.visualization.arrayToDataTable([' >> "${one_spool_fullpath_filename}"

  ## body
  local v_line
  local l_bar l_value l_others l_style l_tooltip
  local v_first_line=true
  l_others=100
  echo "['Bucket', 'Number of Rows', { role: 'style' }, { role: 'tooltip' }]" >> "${one_spool_fullpath_filename}"

  if [ -z "${input_file}" ]
  then
    fc_csv_remove_column "${csv_spool_filename}" "${csv_spool_filename}.2" 1 # row_number
  else
    cp "${csv_spool_filename}" "${csv_spool_filename}.2"
  fi

  while read v_line || [ -n "$v_line" ]
  do
    ${v_first_line} && v_first_line=false && continue
    l_bar=$(${cmd_awk_csv} --source '{a=csv_parse_record($0, separator, enclosure, csv); print csv[0]}' <<< "$v_line")
    l_value=$(${cmd_awk_csv} --source '{a=csv_parse_record($0, separator, enclosure, csv); print csv[1]}' <<< "$v_line")
    l_style=$(${cmd_awk_csv} --source '{a=csv_parse_record($0, separator, enclosure, csv); print csv[2]}' <<< "$v_line")
    l_tooltip=$(${cmd_awk_csv} --source '{a=csv_parse_record($0, separator, enclosure, csv); print csv[3]}' <<< "$v_line")
    if [ ${l_value} -ge ${bar_minperc} ]
    then
      echo ",['${l_bar}', ${l_value}, '${l_style}', '${l_tooltip}']" >> "${one_spool_fullpath_filename}"
      l_others=$(do_calc 'l_others-l_value')
    fi
  done < "${csv_spool_filename}.2"

  rm -f "${csv_spool_filename}.2"

  l_bar="The rest (${l_others}%)"
  l_value=${l_others};
  l_style='D3D3D3' # light gray
  l_tooltip="(${l_others}% of remaining data)";
  if [ ${l_others} -gt 0 -a ${bar_minperc} -gt 0 ] ## For non-percentage bar charts
  then
    echo ",['${l_bar}', ${l_value}, '${l_style}', '${l_tooltip}']" >> "${one_spool_fullpath_filename}"
  fi

  ## bar chart footer
  echo "        ]);" >> "${one_spool_fullpath_filename}"
  echo >> "${one_spool_fullpath_filename}"
  echo "        var options = {" >> "${one_spool_fullpath_filename}"
  echo "                ${chart_option}" >> "${one_spool_fullpath_filename}"
  echo "        };" >> "${one_spool_fullpath_filename}"
  echo "" >> "${one_spool_fullpath_filename}"
  echo "        var chart = new google.visualization.ColumnChart(document.getElementById('barchart'));" >> "${one_spool_fullpath_filename}"
  echo "        chart.draw(data, options);" >> "${one_spool_fullpath_filename}"
  echo "      }" >> "${one_spool_fullpath_filename}"
  echo "    </script>" >> "${one_spool_fullpath_filename}"
  echo >> "${one_spool_fullpath_filename}"
  echo '    <div id="barchart" class="google-chart"></div>' >> "${one_spool_fullpath_filename}"
  echo >> "${one_spool_fullpath_filename}"

  ## footer
  echo '<font class="n">Notes:<br>' >> "${one_spool_fullpath_filename}"
  echo '1) Values are approximated<br>' >> "${one_spool_fullpath_filename}"
  echo '2) Hovering on the bars show more info.' >> "${one_spool_fullpath_filename}"
  [ -n "${foot}" ] && echo "<br>3) ${foot}" >> "${one_spool_fullpath_filename}"
  echo '</font>' >> "${one_spool_fullpath_filename}"

  fc_set_value_var_nvl2 exec_sql_print "${input_file}" 'N' 'Y'
  fc_set_value_var_decode exec_sql_print "${sql_show}" 'N' 'N' "${exec_sql_print}"

  fc_html_topic_end "${one_spool_fullpath_filename}" bar ${exec_sql_print} ${exec_sql_print}

  unset exec_sql_print

  fc_encode_html "${one_spool_fullpath_filename}"

  fc_zip_file "${moat370_zip_filename}" "${one_spool_fullpath_filename}"

  unset chart_option bar_height bar_minperc
  unset one_spool_fullpath_filename
}

fc_proc_graphviz_chart ()
{
  ## add seq to one_spool_filename
  local one_spool_filename="${spool_filename}"
  local one_spool_fullpath_filename

  fc_seq_output_file one_spool_filename
  fc_def_output_file one_spool_fullpath_filename "${one_spool_filename}_graph_chart.html"
  
  [ ! -f "${csv_spool_filename}" ] && echo_error "Can't run fc_proc_graphviz_chart with provided inputs." && return
  [ ! -s "${csv_spool_filename}" ] && echo_time "CSV input is empty." && return

  fc_html_topic_intro "${one_spool_filename}_graph_chart.html" graph
  
  ## chart header
  echo >> "${one_spool_fullpath_filename}"
  echo '    <img id="graph_chart" style="width: 900px; height: 500px;">' >> "${one_spool_fullpath_filename}"
  echo >> "${one_spool_fullpath_filename}"
  echo '    <script type="text/javascript" id="gchart_script">' >> "${one_spool_fullpath_filename}"
  echo "    var dot = 'digraph dot { ' +" >> "${one_spool_fullpath_filename}"
  
  # body
  local v_line l_node1 l_node2 l_attr
  local v_first_line=true

  if [ -z "${input_file}" ]
  then
    fc_csv_remove_column "${csv_spool_filename}" "${csv_spool_filename}.2" 1 # row_number
  else
    cp "${csv_spool_filename}" "${csv_spool_filename}.2"
  fi

  while read v_line || [ -n "$v_line" ]
  do
    ${v_first_line} && v_first_line=false && continue
    l_node1=$(${cmd_awk_csv} --source '{a=csv_parse_record($0, separator, enclosure, csv); print csv[0]}' <<< "$v_line")
    l_node2=$(${cmd_awk_csv} --source '{a=csv_parse_record($0, separator, enclosure, csv); print csv[1]}' <<< "$v_line")
    l_attr=$(${cmd_awk_csv} --source '{a=csv_parse_record($0, separator, enclosure, csv); print csv[2]}' <<< "$v_line")
    fc_clean_file_name l_node1 l_node1
    fc_clean_file_name l_node2 l_node2
    
    echo "'${l_node1} -> ${l_node2} ${l_attr};' +" >> "${one_spool_fullpath_filename}"

  done < "${csv_spool_filename}.2"

  rm -f "${csv_spool_filename}.2"

  echo "    '}';" >> "${one_spool_fullpath_filename}"
  echo '    src = "https://chart.googleapis.com/chart?cht=gv&chs=720x400&chl="+dot' >> "${one_spool_fullpath_filename}"
  echo '    document.getElementById("graph_chart").src=src' >> "${one_spool_fullpath_filename}"
  echo '    </script>' >> "${one_spool_fullpath_filename}"
  
  ## footer
  [ -n "${foot}" ] && echo '<font class="n">Notes:<br>' >> "${one_spool_fullpath_filename}"
  [ -n "${foot}" ] && echo "1) ${foot}" >> "${one_spool_fullpath_filename}"
  [ -n "${foot}" ] && echo '</font>' >> "${one_spool_fullpath_filename}"

  fc_set_value_var_nvl2 exec_sql_print "${input_file}" 'N' 'Y'
  fc_set_value_var_decode exec_sql_print "${sql_show}" 'N' 'N' "${exec_sql_print}"

  fc_html_topic_end "${one_spool_fullpath_filename}" graph ${exec_sql_print} ${exec_sql_print}

  unset exec_sql_print

  fc_encode_html "${one_spool_fullpath_filename}"

  fc_zip_file "${moat370_zip_filename}" "${one_spool_fullpath_filename}"
  
  unset one_spool_fullpath_filename
}