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

## Parse parameter configuration to check if values are compatible.
## Associate input parameters to the variables.

v_msg='When a parameter is defined, all prior parameters must be defined.'

if [ "${moat370_sw_param2}" != 'unset' ] && [ "${moat370_sw_param1}" = 'unset' ]
then
  exit_error ${v_msg}
fi

if [ "${moat370_sw_param3}" != 'unset' ] && [ "${moat370_sw_param1}" = 'unset' -o "${moat370_sw_param2}" = 'unset' ]
then
  exit_error ${v_msg}
fi

if [ "${moat370_sw_param4}" != 'unset' ] && [ "${moat370_sw_param1}" = 'unset' -o "${moat370_sw_param2}" = 'unset' -o "${moat370_sw_param3}" = 'unset' ]
then
  exit_error ${v_msg}
fi

if [ "${moat370_sw_param5}" != 'unset' ] && [ "${moat370_sw_param1}" = 'unset' -o "${moat370_sw_param2}" = 'unset' -o "${moat370_sw_param3}" = 'unset' -o "${moat370_sw_param4}" = 'unset' ]
then
  exit_error ${v_msg}
fi

fc_set_value_var_decode v_p1_check "${moat370_sw_param1}" 'license' 1 0
fc_set_value_var_decode v_p2_check "${moat370_sw_param2}" 'license' 1 0
fc_set_value_var_decode v_p3_check "${moat370_sw_param3}" 'license' 1 0
fc_set_value_var_decode v_p4_check "${moat370_sw_param4}" 'license' 1 0
fc_set_value_var_decode v_p5_check "${moat370_sw_param5}" 'license' 1 0
v_tot_lic=$(do_calc 'v_p1_check+v_p2_check+v_p3_check+v_p4_check+v_p5_check')

if [ $v_tot_lic -gt 1 ]
then
  exit_error 'More than one input parameter defined as "license". Please correct it on "00_software.sql" file.'
fi

unset v_tot_lic

fc_set_value_var_decode v_p1_check "${moat370_sw_param1}" 'section' 1 0
fc_set_value_var_decode v_p2_check "${moat370_sw_param2}" 'section' 1 0
fc_set_value_var_decode v_p3_check "${moat370_sw_param3}" 'section' 1 0
fc_set_value_var_decode v_p4_check "${moat370_sw_param4}" 'section' 1 0
fc_set_value_var_decode v_p5_check "${moat370_sw_param5}" 'section' 1 0
v_tot_sec=$(do_calc 'v_p1_check+v_p2_check+v_p3_check+v_p4_check+v_p5_check')

if [ $v_tot_sec -gt 1 ]
then
  exit_error 'More than one input parameter defined as "section". Please correct it on "00_software.sql" file.'
fi

unset v_tot_sec

v_msg='When a parameter is defined as custom, you must specify the variable that will receive the value.'

if [ "${moat370_sw_param1}" = 'custom' ] && [ -z "${moat370_sw_param1_var}" ]
then
  exit_error ${v_msg}
fi

if [ "${moat370_sw_param2}" = 'custom' ] && [ -z "${moat370_sw_param2_var}" ]
then
  exit_error ${v_msg}
fi

if [ "${moat370_sw_param3}" = 'custom' ] && [ -z "${moat370_sw_param3_var}" ]
then
  exit_error ${v_msg}
fi

if [ "${moat370_sw_param4}" = 'custom' ] && [ -z "${moat370_sw_param4_var}" ]
then
  exit_error ${v_msg}
fi

if [ "${moat370_sw_param5}" = 'custom' ] && [ -z "${moat370_sw_param5_var}" ]
then
  exit_error ${v_msg}
fi

unset v_msg

fc_def_empty_var moat370_param1
fc_def_empty_var moat370_param2
fc_def_empty_var moat370_param3
fc_def_empty_var moat370_param4
fc_def_empty_var moat370_param5

fc_set_value_var_nvl 'moat370_param1' "${in_main_param1}" "${moat370_param1}"
fc_set_value_var_nvl 'moat370_param2' "${in_main_param2}" "${moat370_param2}"
fc_set_value_var_nvl 'moat370_param3' "${in_main_param3}" "${moat370_param3}"
fc_set_value_var_nvl 'moat370_param4' "${in_main_param4}" "${moat370_param4}"
fc_set_value_var_nvl 'moat370_param5' "${in_main_param5}" "${moat370_param5}"

fc_def_empty_var license_pack_param
fc_set_value_var_decode 'license_pack_param' "${moat370_sw_param1}" 'license' "${moat370_param1}" "${license_pack_param}"
fc_set_value_var_decode 'license_pack_param' "${moat370_sw_param2}" 'license' "${moat370_param2}" "${license_pack_param}"
fc_set_value_var_decode 'license_pack_param' "${moat370_sw_param3}" 'license' "${moat370_param3}" "${license_pack_param}"
fc_set_value_var_decode 'license_pack_param' "${moat370_sw_param4}" 'license' "${moat370_param4}" "${license_pack_param}"
fc_set_value_var_decode 'license_pack_param' "${moat370_sw_param5}" 'license' "${moat370_param5}" "${license_pack_param}"

fc_def_empty_var sections_param
fc_set_value_var_decode 'sections_param' "${moat370_sw_param1}" 'section' "${moat370_param1}" "${sections_param}"
fc_set_value_var_decode 'sections_param' "${moat370_sw_param2}" 'section' "${moat370_param2}" "${sections_param}"
fc_set_value_var_decode 'sections_param' "${moat370_sw_param3}" 'section' "${moat370_param3}" "${sections_param}"
fc_set_value_var_decode 'sections_param' "${moat370_sw_param4}" 'section' "${moat370_param4}" "${sections_param}"
fc_set_value_var_decode 'sections_param' "${moat370_sw_param5}" 'section' "${moat370_param5}" "${sections_param}"

## Param 1
if [ "${moat370_sw_param1}" = 'custom' ]
then
  eval ${moat370_sw_param1_var}=\${moat370_param1}
fi

## Param 2
if [ "${moat370_sw_param2}" = 'custom' ]
then
  eval ${moat370_sw_param2_var}=\${moat370_param2}
fi

## Param 3
if [ "${moat370_sw_param3}" = 'custom' ]
then
  eval ${moat370_sw_param3_var}=\${moat370_param3}
fi

## Param 4
if [ "${moat370_sw_param4}" = 'custom' ]
then
  eval ${moat370_sw_param4_var}=\${moat370_param4}
fi

## Param 5
if [ "${moat370_sw_param5}" = 'custom' ]
then
  eval ${moat370_sw_param5_var}=\${moat370_param5}
fi

unset v_p1_check v_p2_check v_p3_check v_p4_check v_p5_check
unset moat370_param1 moat370_param2 moat370_param3 moat370_param4 moat370_param5