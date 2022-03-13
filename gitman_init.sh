#!/usr/bin/env bash
set -eu

# Move to realpath
cd $(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

# Read command line args
ProjectID=""
[[ "$#" > "0" ]] && ProjectID="$*"

function CleanID {
  local id="$*"
  id="$(sed 's/ /-/ig' <<< ""${id}"")"
  id="$(sed 's/[^a-z0-9_-]//ig' <<< ""${id}"")"
  echo "$id"
}

# This specifically doesn't use a sub-shell to hopefully work around the prompt issue
function AskForProjectID {
  local __resultvar=$1
  local str
  echo "This is a test echo inside a function before a read call"
  read str
  echo "The value entered was: ${str}"
  str=$(CleanID "${str}")
  
  [[ -n "$__resultvar" ]] && eval $__resultvar="${str}" || echo "${str}"
}

function showDotEnvInstructions {
  echo "Instructions to update .env file"
}

function showMutagenInstructions {
  echo "Instructions to update mutagen.yml file"
}

SOURCE_NAME="${PWD##*/}"
GITMAN_ROOT="../../"
PERSIST_DIR="${GITMAN_ROOT}"
GITMAN_LOCATION=$(cd $(pwd -P)/../;echo ${PWD##*/})
SOURCE_DIR_FROM_PERSIST_DIR="${GITMAN_LOCATION}/${SOURCE_NAME}"

#echo "Source Name: ${SOURCE_NAME}"
#echo "GitMan Root: ${GITMAN_ROOT}"
#echo "GitMan Location: ${GITMAN_LOCATION}"
#echo "Source Dir from Persist Dir: ${SOURCE_DIR_FROM_PERSIST_DIR}"

while [[ -z "${ProjectID}" ]]; do
  AskForProjectID ProjectID
done

echo "Cleaned Project ID: '${ProjectID}'"

# Link from source directory to persistent directory
[[ -L persistent ]] || ln -s ${PERSIST_DIR} persistent

# Create symlinks for things that don't change each project
[[ -L persistent/database ]] || ln -s database persistent/database
[[ -L persistent/elasticsearch ]] || ln -s elasticsearch persistent/elasticsearch

# Copy sample configuration directories if they do not exist yet.
[[ -d persistent/nginx ]] || cp -R nginx persistent/
[[ -d persistent/secrets ]] || mkdir persistent/secrets
[[ -d persistent/varnish ]] || cp -R varnish persistent/

# Copy sample files to persistent directory if they do not exist yet.
[[ -f persistent/.gitignore ]] || cp .gitignore.sample persistent/.gitignore
[[ -f persistent/docker-compose.yml ]] || cp docker-compose.yml persistent/docker-compose.yml
#[[ -f persistent/.env ]] || awk -v prjid="${ProjectID}" '{gsub(/{{ID}}/,prjid,$0); print $0}' templates/.env > persistent/.env
#[[ -f persistent/mutagen.yml ]] || awk -v prjid="${ProjectID}" '{gsub(/{{ID}}/,prjid,$0); print $0}' templates/mutagen.yml > persistent/mutagen.yml

# Generate database passwords if they don't exist
[[ -f persistent/secrets/mariadb.root.secret ]] || cat /dev/urandom | LC_CTYPE=C tr -dc '[:alnum:][:punct:]' | fold -w 32 | head -n 1 > persistent/secrets/mariadb.root.secret
[[ -f persistent/secrets/mariadb.user.secret ]] || cat /dev/urandom | LC_CTYPE=C tr -dc '[:alnum:][:punct:]' | fold -w 16 | head -n 1 > persistent/secrets/mariadb.user.secret

[[ grep '{{ID}}' persistent/.env ]] && showDotEnvInstructions
[[ grep '{{ID}}' persistent/mutagen.yml ]] && showMutagenInstructions
