#!/usr/bin/env bash
set -eu

# Move to realpath
cd $(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

function CleanID {
  local id="$1"
  id="$(sed 's/[^a-z0-9_-]//ig' <<< "${id}")"
  id
}

SOURCE_NAME="${PWD##*/}"
GITMAN_ROOT="../../"
PERSIST_DIR="${GITMAN_ROOT}"
GITMAN_LOCATION=$(cd $(pwd -P)/../;echo ${PWD##*/})
SOURCE_DIR_FROM_PERSIST_DIR="${GITMAN_LOCATION}/${SOURCE_NAME}"

echo "Source Name: ${SOURCE_NAME}"
echo "GitMan Root: ${GITMAN_ROOT}"
echo "GitMan Location: ${GITMAN_LOCATION}"
echo "Source Dir from Persist Dir: ${SOURCE_DIR_FROM_PERSIST_DIR}"

read -p "Enter Project Name: " ProjectID
ProjectID="$(CleanID ""${ProjectID}"")"

while [[ -z "${ProjectID}" ]]; do
  read -p "Enter Project Name: " ProjectID
  ProjectID="$(CleanID ""${ProjectID}"")"
done

echo "Cleaned Project ID: '${ProjectID}'"

# Link from source directory to persistent directory
[[ -L persistent ]] || ln -s ${PERSIST_DIR} persistent

# Link from persistent directory to source
[[ -L persistent/source ]] || ln -s ${SOURCE_DIR_FROM_PERSIST_DIR} persistent/source

# Create symlinks for things that don't change each project
[[ -L persisent/database ]] || ln -s database persistent/database
[[ -L persisent/elasticsearch ]] || ln -s elasticsearch persistent/elasticsearch

# Copy sample configuration directories if they do not exist yet.
[[ -d persisent/nginx ]] || cp -R nginx persisent/
[[ -d persisent/secrets ]] || mkdir persisent/secrets
[[ -d persisent/varnish ]] || cp -R varnish persisent/

# Copy sample files to persistent directory if they do not exist yet.
[[ -f persistent/.gitignore ]] || cp .gitignore.sample persistent/.gitignore
[[ -f persistent/docker-compose.yml ]] || cp docker-compose.yml persistent/docker-compose.yml
[[ -f persistent/.env ]] || awk -v prjid="${ProjectID}" '{gsub(/{{ID}}/,prjid,$0); print $0}' templates/.env > persistent/.env
[[ -f persistent/mutagen.yml ]] || awk -v prjid="${ProjectID}" '{gsub(/{{ID}}/,prjid,$0); print $0}' templates/mutagen.yml > persistent/mutagen.yml

# Generate database passwords if they don't exist
[[ -f persisent/secrets/mariadb.root.secret ]] || cat /dev/urandom | LC_CTYPE=C tr -dc '[:alnum:][:punct:]' | fold -w ${1:-32} | head -n 1 > mariadb.root.secret
[[ -f persisent/secrets/mariadb.user.secret ]] || cat /dev/urandom | LC_CTYPE=C tr -dc '[:alnum:][:punct:]' | fold -w ${1:-16} | head -n 1 > mariadb.user.secret
