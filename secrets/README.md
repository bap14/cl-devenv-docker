# Generating Random Strings Easily (MacOS)

Simply execute the following to create two files with random strings that can be used for passwords:

`cat /dev/urandom | LC_CTYPE=C tr -dc '[:alnum:][:punct:]' | fold -w 32 | head -n 1 > mariadb.root.secret`
`cat /dev/urandom | LC_CTYPE=C tr -dc '[:alnum:][:punct:]' | fold -w 16 | head -n 1 > mariadb.user.secret`
