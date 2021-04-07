fc_clean_file_name "moat370_log" "moat370_file_nopath" "PATH"
title="File: ${moat370_file_nopath}"

input_file=${moat370_log}
one_spool_text_file_rename='N'

output_type="text"
fc_exec_item

##--------------

fc_clean_file_name "moat370_log2" "moat370_file_nopath" "PATH"
title="File: ${moat370_file_nopath}"

input_file=${moat370_log2}
one_spool_text_file_rename='N'

output_type="text"
fc_exec_item

##--------------

fc_clean_file_name "moat370_log3" "moat370_file_nopath" "PATH"
title="File: ${moat370_file_nopath}"

input_file=${moat370_log3}
one_spool_text_file_rename='N'

output_type="text"
fc_exec_item

##--------------

fc_seq_output_file v_database_in_file

fc_clean_file_name "v_database_in_file" "moat370_file_nopath" "PATH"
title="Database Input Log: ${moat370_file_nopath}"

input_file=${v_database_in_file}
one_spool_text_file_rename='N'

output_type="text"
fc_exec_item

##--------------

fc_seq_output_file v_database_out_file

fc_clean_file_name "v_database_out_file" "moat370_file_nopath" "PATH"
title="Database Output Log: ${moat370_file_nopath}"

input_file=${v_database_out_file}
one_spool_text_file_rename='N'

output_type="text"
fc_exec_item

##--------------

unset moat370_file_nopath