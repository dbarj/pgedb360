fc_oracle_tkprof

echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Alert log (3 methods)
db_name_upper=$(upper_var "${database_name}")
db_name_lower=$(lower_var "${database_name}")

cp "${background_dump_dest}"/alert_${db_name_upper}*.log "${moat370_sw_output_fdr}/" >> "${moat370_log3}" 2> "${moat370_log3}"
cp "${background_dump_dest}"/alert_${db_name_lower}*.log "${moat370_sw_output_fdr}/" >> "${moat370_log3}" 2> "${moat370_log3}"
cp "${background_dump_dest}"/alert_${_connect_identifier}.log "${moat370_sw_output_fdr}/" >> "${moat370_log3}" 2> "${moat370_log3}"

## Altered to be compatible with SunOS:
## HOS rename alert_ ${moat370_alert}_ alert_*.log >> ${moat370_log3}

ls -1 "${moat370_sw_output_fdr}"/alert_*.log 2> "${moat370_log3}" | while read line || [ -n "$line" ]
do
  mv "$line" ${moat370_alert}_$(basename "$line")
done >> "${moat370_log3}"

fc_zip_file "${moat370_zip_filename}" "${moat370_alert}*.log"

if [ "${moat370_conf_incl_opatch}" = 'Y' ]
then
  if ls $ORACLE_HOME/cfgtoollogs/opatch/opatch* 1> /dev/null 2>&1
  then
    zip -j "${moat370_opatch}" $ORACLE_HOME/cfgtoollogs/opatch/opatch* >> "${moat370_log3}"
  fi
fi

if [ -f "${moat370_opatch}" ]
then
  fc_zip_file "${moat370_zip_filename}" "${moat370_opatch}"
fi

############