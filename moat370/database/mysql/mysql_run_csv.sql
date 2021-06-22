tee %%file_name%%
source %%query_file%%
notee

tee %%error_file%%
SHOW ERRORS;
notee