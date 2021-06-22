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

########################
# Mandatory Functions: #
########################

# fc_db_startup_connection
# fc_db_end_connection
# fc_db_check_connection
# fc_db_begin_code
# fc_db_end_code
# fc_db_run_file
# fc_db_define_module
# fc_db_reset_options
# fc_db_pre_section_call
# fc_db_create_csv
# fc_db_table_description
# fc_db_check_file_sql_error
# fc_db_enable_trace
# fc_db_pre_exec_call
# fc_db_sql_transform

########################

fc_db_startup_connection ()
{
  true
}

fc_db_end_connection ()
{
  true
}

fc_db_check_connection ()
{
  true
}

fc_db_begin_code ()
{
  hosts_count=1
  avg_core_count=1
  avg_thread_count=1
  database_name=db
  host_name=host
  db_version=v1
}

fc_db_end_code ()
{
  true
}

fc_db_run_file ()
{
  true
}

fc_db_define_module ()
{
  true
}

fc_db_reset_options ()
{
  true
}

fc_db_pre_section_call ()
{
  true
}

fc_db_create_csv ()
{
  true
}

fc_db_table_description ()
{
  true
}

fc_db_check_file_sql_error ()
{
  true
}

fc_db_enable_trace ()
{
  true
}

fc_db_pre_exec_call ()
{
  true
}

fc_db_sql_transform ()
{
  true
}