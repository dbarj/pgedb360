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

## End Time
moat370_main_time1=$(get_secs)

total_hours="Tool execution time: $(convert_secs $(do_calc 'moat370_main_time1-moat370_main_time0'))."

moat370_time_stamp=$(date "${moat370_date_format}")
fc_paste_file_replacing_variables "${moat370_fdr_cfg}"/moat370_html_footer.html "${moat370_main_report}"

fc_encode_html "${moat370_main_report}" 'INDEX'

## Readme
echo "1. Unzip ${moat370_zip_filename_nopath} into a directory" > "${moat370_readme}"
echo "2. Review ${moat370_main_report_nopath}" >> "${moat370_readme}"

## encrypt final files
## fc_convert_txt_to_html ${moat370_log}
## fc_encode_html ${moat370_log}
## fc_convert_txt_to_html ${moat370_log2}
## fc_encode_html ${moat370_log2}

## Zip
fc_def_empty_var moat370_d3_usage
if [ "${moat370_d3_usage}" = 'Y' ]
then
  fc_zip_file "${moat370_zip_filename}" "${moat370_fdr_js}/d3.min.js" false
fi

fc_clean_file_name "moat370_log3" "moat370_log3_nopath" "PATH"

fc_def_empty_var moat370_tf_usage
if [ "${moat370_tf_usage}" = 'Y' ]
then
  v_zipfdr=$(dirname "${moat370_zip_filename}")
  cp -av ${moat370_fdr_js}/tablefilter "${moat370_sw_output_fdr}/" >> "${moat370_log3}"
  cd "${moat370_sw_output_fdr}/"
  zip -rm $(cd - >/dev/null; cd "${v_zipfdr}"; pwd)/${moat370_zip_filename_nopath} tablefilter/ >> "${moat370_log3_nopath}"
  cd - >/dev/null
fi 
## Fix above cmd as cur folder can be RO

if [ -z "${moat370_pre_sw_key_file}" ]
then
  rm -f "${enc_key_file}"
fi

# Disconnect
fc_db_end_connection

fc_zip_file "${moat370_zip_filename}" "${moat370_driver}"
fc_zip_file "${moat370_zip_filename}" "${moat370_log2}"
fc_zip_file "${moat370_zip_filename}" "${moat370_log}" 
fc_zip_file "${moat370_zip_filename}" "${moat370_main_report}"
fc_zip_file "${moat370_zip_filename}" "${moat370_readme}"

unzip -l "${moat370_zip_filename}" >> "${moat370_log3}"
zip -mj "${moat370_zip_filename}" "${moat370_log3}" > /dev/null