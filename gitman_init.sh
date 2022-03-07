#!/usr/bin/env bash
set -eu

# Move to realpath
cd $(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

SOURCE_NAME="${PWD##*/}"
GITMAN_ROOT="../../"
GITMAN_LOCATION=$(cd $(pwd -P)/../;echo ${PWD##*/})
CLEAN_ID="$(sed 's/[^a-z0-9_-]//ig' <<< "${SOURCE_NAME}")"

echo "Source Name: ${SOURCE_NAME}"
echo "GitMan Root: ${GITMAN_ROOT}"
echo "GitMan Location: ${GITMAN_LOCATION}"
echo "Clean ID: ${CLEAN_ID}"
