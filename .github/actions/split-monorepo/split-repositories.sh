#!/bin/bash

set -eo pipefail

GH_TOKEN=$1
PACKAGE=$2
ORGANIZATION=$3
BRANCH=$4
FORCE=${5:-false}

TMP="tmp_split/${RANDOM}"
URL="https://${GH_TOKEN}@github.com/${ORGANIZATION}/${PACKAGE}"

set -u

DIR_PWD=`pwd`

echo "Monorepo Split – ${PACKAGE}"

echo "Init environment"

if [[ "$FORCE" == true ]]; then
  PUSH_OPTS="--force"
else
  PUSH_OPTS=""
fi

cd ${DIR_PWD}
echo "mkdir -p ${DIR_PWD}/${TMP}/${PACKAGE}"
mkdir -p ${DIR_PWD}/${TMP}/${PACKAGE}

echo "git clone --bare .git ${DIR_PWD}/${TMP}/${PACKAGE}"
git clone --bare .git ${DIR_PWD}/${TMP}/${PACKAGE}

echo "cd ${DIR_PWD}/${TMP}/${PACKAGE}"
cd ${DIR_PWD}/${TMP}/${PACKAGE}

echo "git filter-repo --subdirectory-filter packages/${PACKAGE} --force"
git filter-repo --subdirectory-filter packages/${PACKAGE} --force

echo "git push dry-run"
git push "${URL}.git" ${BRANCH} --dry-run ${PUSH_OPTS} --verbose

echo "git push"
git push "${URL}.git" ${BRANCH} ${PUSH_OPTS} --verbose
git push "${URL}.git" ${BRANCH} --tags --verbose
