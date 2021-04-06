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

# set -eo pipefail
set -Eo pipefail

if [ -z "${BASH_VERSION}" -o "${BASH}" = "/bin/sh" ]
then
  >&2 echo "Script must be executed in BASH shell."
  exit 1
fi

set -u # This was moved here to avoid empty BASH_VERSION or BASH to fail.

# Arguments
v_parameters=("$@")

v_this_script="$(basename -- "$0")"
v_this_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P)"
moat370_fdr="$(cd -P "$v_this_dir/.."; pwd)"
# v_this_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P) # Folder of this script

# Load all code functions.
source "${moat370_fdr}"/sh/moat370_functions_core.sh
source "${moat370_fdr}"/sh/moat370_functions_datatypes.sh
source "${moat370_fdr}"/sh/moat370_functions_procsql.sh
source "${moat370_fdr}"/sh/moat370_functions_csv_parser.sh
source "${moat370_fdr}"/sh/moat370_functions_charts.sh

trap 'trap_error $LINENO' ERR
trap 'exit_error "Code interrupted."' SIGINT SIGTERM

bin_check_exit awk
bin_check_exit mkfifo

source "${moat370_fdr}"/sh/moat370_0b_pre.sh

section_id='0a'
fc_db_define_module

fc_reset_defaults

## Load custom pre if exists
v_list=$(ls -1 "${moat370_sw_folder}"/sh/${moat370_sw_name}_0*_pre.sh "${moat370_sw_folder}"/sql/${moat370_sw_name}_0*_pre.sql 2> /dev/null || true)
v_list=$(sed 's:.*/::' <<< "${v_list}" | sort)

for v_file in ${v_list}
do
  v_file_extension=$(sed 's:.*\.::' <<< "${v_file}")
  if [ -f "${moat370_sw_folder}/${v_file_extension}/${v_file}" ]
  then
    fc_echo_screen_log ""
    fc_echo_screen_log division
    fc_echo_screen_log ""
    fc_echo_screen_log "Running ${v_file}"
    if [ "${v_file_extension}" = "sh" ]
    then
      source "${moat370_sw_folder}/${v_file_extension}/${v_file}"
    elif [ "${v_file_extension}" = "sql" ]
    then
      fc_db_run_file "${moat370_sw_folder}/${v_file_extension}/${v_file}"
    fi
  fi
done

unset v_file v_file_extension v_list

## Report # of columns
moat370_total_cols=${moat370_sw_rpt_cols}

echo '<!--BEGIN_SENSITIVE_DATA-->' >> "${moat370_main_report}"
echo '<table><tr class="main">' >> "${moat370_main_report}"

v_i=1
while [ ${v_i} -le ${moat370_total_cols} ]
do
  if [ ${v_i} -eq 1 ]
  then
    echo "<td class=\"c\">${v_i}/${moat370_total_cols}</td>" >> "${moat370_main_report}"
  else
    echo "<td class=\"c i${v_i}\">${v_i}/${moat370_total_cols}</td>" >> "${moat370_main_report}"
  fi
  v_i=$(do_calc "${v_i}+1")
done

echo '</tr><tr class="main"><td>' >> "${moat370_main_report}"
echo "<img src=\"${moat370_sw_logo_file}\" alt=\"${moat370_sw_name}\" height=\"228\" width=\"auto\"" >> "${moat370_main_report}"
echo "title=\"${moat370_sw_logo_title}\">" >> "${moat370_main_report}"
echo '<br>' >> "${moat370_main_report}"

fc_def_output_file step_main_file_driver 'step_main_file_driver_columns.sql'

v_i=1
while [ ${v_i} -le ${moat370_total_cols} ]
do
  fc_load_column "${v_i}"
  if [ ${v_i} -lt ${moat370_total_cols} ]
  then
    echo "</td><td class=\"i`expr ${v_i} + 1`\">" >> "${moat370_main_report}"
  else
    echo '</td>' >> "${moat370_main_report}"
  fi
  v_i=$(do_calc "${v_i}+1")
done

## main footer
echo '</tr></table>' >> "${moat370_main_report}"
echo '<!--END_SENSITIVE_DATA-->' >> "${moat370_main_report}"

fc_db_end_code

section_id='0c'
fc_db_define_module

## Load custom post if exists
v_list=$(ls -1 "${moat370_sw_folder}"/sh/${moat370_sw_name}_0*_post.sh "${moat370_sw_folder}"/sql/${moat370_sw_name}_0*_post.sql 2> /dev/null || true)
v_list=$(sed 's:.*/::' <<< "${v_list}" | sort)

for v_file in ${v_list}
do
  v_file_extension=$(sed 's:.*\.::' <<< "${v_file}")
  if [ -f "${moat370_sw_folder}/${v_file_extension}/${v_file}" ]
  then
    fc_echo_screen_log ""
    fc_echo_screen_log division
    fc_echo_screen_log ""
    fc_echo_screen_log "Running ${v_file}"
    if [ "${v_file_extension}" = "sh" ]
    then
      source "${moat370_sw_folder}/${v_file_extension}/${v_file}"
    elif [ "${v_file_extension}" = "sql" ]
    then
      fc_db_run_file "${moat370_sw_folder}/${v_file_extension}/${v_file}"
    fi
  fi
done

unset v_file v_file_extension v_list

source "${moat370_fdr_sh}"/moat370_0c_post.sh

fc_encrypt_output_zip moat370_zip_filename

if grep -q '.zip$' <<< "${moat370_zip_filename}"
then
  # Not using fc_echo_screen_log as log file is already zipped
  echo ""
  echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
  echo ""
  unzip -l "${moat370_zip_filename}"
fi

[ -s "${moat370_error_file}" ] && echo_time "Check \"${moat370_error_file}\" for errors that happened during execution."

echo "End ${moat370_sw_name}. Output: ${moat370_zip_filename}"

## END