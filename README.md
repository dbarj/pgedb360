# pgedb360

pgedb360 is a tool to get PostgreSQL overall activity, generate the execution plan of the top sqls and get all the relevant information that the planner used to generate that plan.

pgedb360 is based on [MOAT370 Framework](https://github.com/dbarj/moat370).

## Execution Steps ##

1. Download and unzip latest pgedb360 version and, navigate to the root of pgedb360-master directory:

```
$ wget -O pgedb360.zip https://github.com/dbarj/pgedb360/archive/master.zip
$ unzip pgedb360.zip
$ cd pgedb360-master/
```

2. Execute pgedb360.sh:

```
$ read -s PGPASSWORD
xxxxxx
$ export PGPASSWORD
$ bash pgedb360.sh '-h localhost -p 5432 -d postgres -U postgres'
```

## Results ##

1. Unzip output **pgedb360_dbname_hostname_YYYYMMDD_HH24MI.zip** into a directory on your PC.

2. Review main html file **00001_pgedb360_dbname_index.html**.