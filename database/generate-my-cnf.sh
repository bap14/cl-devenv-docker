#!/bin/sh

if [ ! -f ~/.my.cnf ]; then
    PWD=$(cat $MARIADB_PASSWORD_FILE)
    cat <<EOF > ~/.my.cnf
[client]
host = localhost
user = $MARIADB_USER
password = $PWD
[mysql]
database = $MARIADB_DATABASE
EOF
fi
