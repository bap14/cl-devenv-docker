#!/usr/bin/env bash
set -eu

# Move to realpath
cd $(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

SOURCE_NAME="${PWD##*/}"
GITMAN_ROOT="../../"
PERSIST_DIR="${GITMAN_ROOT}"
GITMAN_LOCATION=$(cd $(pwd -P)/../;echo ${PWD##*/})
CLEAN_ID="$(sed 's/[^a-z0-9_-]//ig' <<< "${SOURCE_NAME}")"

echo "Source Name: ${SOURCE_NAME}"
echo "GitMan Root: ${GITMAN_ROOT}"
echo "GitMan Location: ${GITMAN_LOCATION}"
echo "Clean ID: ${CLEAN_ID}"

ProjectID=""
while [[ "${ProjectID}" == "" ]]; do
  read -p 'Project Name []: ' ProjectID
  ProjectID="$(sed 's/[^a-z0-9_-]//ig' <<< "${ProjectID}")"
done

echo "Project ID: '${ProjectID}'"

# Link from source directory to persistent directory
[[ -L persistent ]] || ln -s ${PERSIST_DIR} persistent

# Copy sample files to persistent directory if they do not exist yet.
[[ -f persistent/.gitignore ]] || cp .gitignore.sample persistent/.gitignore
[[ -f persistent/.env ]] || awk '{gsub(/#{}/,"'${ProjectID}'",$0); print $0}' templates/.env persistent/.env
[[ -f persistent/mutagen.yml ]] || awk '{gsub(/#{}/,"'${ProjectID}'",$0); print $0}' templates/mutagen.yml persistent/mutagen.yml
