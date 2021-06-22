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

get_date_time ()
{
  date '+%Y%m%d_%H%M%S'
}

get_time ()
{
  date '+%H:%M:%S'
}

get_secs ()
{
  date '+%s'
}

convert_secs ()
{
  local h m s v_sec
  v_sec="$1"
  # Return seconds in HH:MI:SS format.
  h=$(do_calc 'v_sec/3600')
  m=$(do_calc '(v_sec%3600)/60')
  s=$(do_calc 'v_sec%60')
  printf "%02d:%02d:%02d\n" $h $m $s
  # The OR TRUE is due to output 0 gives a return 1.
}

trim_var ()
{

  set +u
  local in_char="$2"
  fc_enable_set_u
  [ -z "${in_char}" ] && in_char=" "

  sed "s/^${in_char}*//g ; s/${in_char}*$//g" <<< "$1"
}

upper_var ()
{
  tr [:lower:] [:upper:] <<< "$1"
}

lower_var ()
{
  tr [:upper:] [:lower:] <<< "$1"
}

greatest_num ()
{
  if [ $1 -gt $2 ]
  then
      echo $1
  else
      echo $2
  fi
}

check_input_format ()
{
  local INPUT_DATE="$1"
  local INPUT_FORMAT="%Y-%m-%d"
  local OUTPUT_FORMAT="%Y-%m-%d"
  local UNAME=$(uname)

  if [ "$UNAME" = "Darwin" ] # Mac OS X
  then 
    date -j -f "$INPUT_FORMAT" "$INPUT_DATE" +"$OUTPUT_FORMAT" >/dev/null 2>&- || exit_error "Date ${INPUT_DATE} in wrong format. Specify YYYY-MM-DD."
  elif [ "$UNAME" = "Linux" ] # Linux
  then
    date -d "$INPUT_DATE" +"$OUTPUT_FORMAT" >/dev/null 2>&- || exit_error "Date ${INPUT_DATE} in wrong format. Specify YYYY-MM-DD."
  else # Unsupported system
    date -d "$INPUT_DATE" +"$OUTPUT_FORMAT" >/dev/null 2>&- || exit_error "Unsupported system"
  fi
  [ ${#INPUT_DATE} -eq 10 ] || exit_error "Date ${INPUT_DATE} in wrong format. Specify YYYY-MM-DD."
}

ConvYMDToEpoch ()
{
  local v_in_date="$1"
  case "$(uname -s)" in
      Linux*)     echo $(date -u '+%s' -d ${v_in_date});;
      Darwin*)    echo $(date -j -u -f '%Y-%m-%d %T' "${v_in_date} 00:00:00" +"%s");;
      *)          echo
  esac  
}

ConvEpochToYMD ()
{
  local v_in_epoch="$1"
  case "$(uname -s)" in
      Linux*)     echo $(date -u '+%Y-%m-%d' -d @${v_in_epoch});;
      Darwin*)    echo $(date -j -u -f '%s' "${v_in_epoch}" +"%Y-%m-%d");;
      *)          echo
  esac  
}

ConvSecsToDays ()
{
  local v_in_epoch=$1
  echo $(do_calc 'v_in_epoch/24/3600')
}

substr_var ()
{
  local v_len
  v_len=$(do_calc "$2+$3-1")
  cut -c$2-$v_len <<< "$1"
}

instr_var ()
{
  # 1 = String
  # 2 = Sub_String
  # 3 = Nth Occurrence. Default = 1
  # Output = Position. 0 = Not Found.

  local v_sstr v_occur

  set +u
  [ "$3" != "" ] && v_occur="$3" || v_occur=1
  fc_enable_set_u

  v_sstr=$(sed 's/[]\.|$(){}?+*^]/\\\\&/g' <<< "$2")
  $cmd_awk -v sstr="$v_sstr" -v occur="$v_occur" \
  '{
    i=1; idx=0; npos=1; str=$0
    while(i>0) { 
      i=match(str,sstr); 
      if(i>0) {
        idx += i;
        if (npos==occur) print idx;
        str=substr(str, i+1);
        npos += 1;
      }
      else if (idx==0)
      {
        print 0;
      }
    }
   }' <<< "$1"

}

ere_quote ()
{
  # Quote regex characters on string
  ${cmd_sed} 's/[]\.|$(){}?+*^]/\\&/g' <<< "$*"
}

do_calc ()
{
  echo "$(($1))"
}

#### END OF FILE ####