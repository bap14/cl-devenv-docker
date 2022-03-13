#!/usr/bin/env bash
set -eu

# Clean an identifier to only allow letters, numbers, underscores and dashes
function CleanID {
  echo "Cleaning string">&2
  local id="$*"
  # Start with a letter or number
  id="$(sed 's/^[^a-z0-9]*//i' <<< ""${id}"")"
  # End with a letter or number
  id="$(sed 's/[^a-z0-9]*$//i' <<< ""${id}"")"
  # Swap spaces for dashes
  id="$(sed 's/ /-/ig' <<< ""${id}"")"
  # Replace all duplicate dashes with single dash
  id="$(sed 's/---*/-/g' <<< ""${id}"")"
  # Remove anything that isn't a letter, number, underscore or dash
  id="$(sed 's/[^a-z0-9_-]//ig' <<< ""${id}"")"
  echo "$id"
}

# Prompt for user-input for a project identifier if one is not provided via 
# args
function AskForProjectID {
  # The name of the variable to be populated (optional, required if this 
  # should not be executed in subshell)
  local __resultvar=$1
  local str
  echo "Please enter a project identifier (e.g. devenv):"
  read str
  str=$(CleanID "${str}")
  
  if [[ "$__resultvar" ]]; then
    eval $__resultvar="${str}"
  else
    echo "${str}"
  fi
}

function WriteRandomStringToFile {
  local length="32"
  local file=""

  if [[ "$#" == 0 ]]; then
    echo "File parameter must be supplied"
    exit 1
  fi

  [[ "$1" ]] && file="$1"

  if [[ "$#" > 1 ]]; then
    [[ "$2" ]] && length="$2"
    [[ "$2" > 0 ]] || length="32"
  fi

  cat /dev/urandom \
    | LC_CTYPE=C tr -dc '[:alnum:][:punct:]' \
    | fold -w $length \
    | head -n 1 > "$file"
}

# Move to realpath
cd $(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

# Read all command line args as project identifier
ProjectID=""
[[ "$#" > "0" ]] && ProjectID=$(CleanID "$*")

SOURCE_NAME="${PWD##*/}"
GITMAN_ROOT="../../"
PERSIST_DIR="${GITMAN_ROOT}"
GITMAN_LOCATION=$(cd $(pwd -P)/../;echo ${PWD##*/})
SOURCE_DIR_FROM_PERSIST_DIR="${GITMAN_LOCATION}/${SOURCE_NAME}"

#echo "Source Name: ${SOURCE_NAME}"
#echo "GitMan Root: ${GITMAN_ROOT}"
#echo "GitMan Location: ${GITMAN_LOCATION}"
#echo "Source Dir from Persist Dir: ${SOURCE_DIR_FROM_PERSIST_DIR}"

# If no project identifier passed, prompt for one
while [[ -z "${ProjectID}" ]]; do
  AskForProjectID ProjectID
done

# Link from source directory to persistent directory
[[ -L persistent ]] || ln -s ${PERSIST_DIR} persistent

# Link from persistent directory to source
[[ -L persistent/source ]] || ln -s ${SOURCE_DIR_FROM_PERSIST_DIR} persistent/source

# Create symlinks for things that don't change each project
[[ -d persistent/database || -L persistent/database ]] || ln -s source/database persistent/database
[[ -d persistent/elasticsearch || -L persistent/elasticsearch ]] || ln -s source/elasticsearch persistent/elasticsearch

# Copy sample configuration directories if they do not exist yet.
[[ -d persistent/nginx ]] || cp -R nginx persistent/
[[ -d persistent/secrets ]] || mkdir persistent/secrets
[[ -d persistent/varnish ]] || cp -R varnish persistent/

# Copy sample files to persistent directory if they do not exist yet.
[[ -f persistent/.gitignore ]] || cp .gitignore.sample persistent/.gitignore
[[ -f persistent/docker-compose.yml ]] || cp docker-compose.yml persistent/docker-compose.yml

# Generate files and replace placeholder with project identifier
[[ -f persistent/.env ]] || awk -v prjid="${ProjectID}" '{gsub(/{{ID}}/,prjid,$0); print $0}' templates/.env > persistent/.env
[[ -f persistent/mutagen.yml ]] || awk -v prjid="${ProjectID}" '{gsub(/{{ID}}/,prjid,$0); print $0}' templates/mutagen.yml > persistent/mutagen.yml

# Generate database passwords if they don't exist
[[ -f persistent/secrets/mariadb.root.secret ]] || WriteRandomStringToFile persistent/secrets/mariadb.root.secret
[[ -f persistent/secrets/mariadb.user.secret ]] || WriteRandomStringToFile persistent/secrets/mariadb.user.secret 16
