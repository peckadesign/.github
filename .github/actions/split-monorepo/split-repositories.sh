#!/bin/bash

set -eo pipefail

GH_TOKEN=$1
PACKAGE=$2
ORGANIZATION=$3
BRANCH=$4
FORCE=${5:-false}
PUSH_TAG=${6:-false}

TMP="tmp_split/${RANDOM}"
URL="https://github.com/${ORGANIZATION}/${PACKAGE}.git"

# Token goes in a header instead of the URL: git drops URL credentials when GitHub redirects the push
AUTH_BASIC=$(printf 'x-access-token:%s' "${GH_TOKEN}" | base64 -w0)
echo "::add-mask::${AUTH_BASIC}"
AUTH_HEADER="AUTHORIZATION: basic ${AUTH_BASIC}"

set -u

git_push() {
  git -c credential.helper= -c "http.https://github.com/.extraheader=${AUTH_HEADER}" push "${URL}" "$@"
}

# Retries transient failures; an authentication failure is not retried
push_with_retry() {
  local attempt output
  for attempt in 1 2 3; do
    if output=$(git_push "$@" 2>&1); then
      echo "${output}"
      return 0
    fi
    echo "${output}"
    if grep -qiE "could not read (Username|Password)|Authentication failed|Invalid username or password|Permission to .* denied|returned error: 40[13]" <<< "${output}"; then
      echo "::error::Push to ${ORGANIZATION}/${PACKAGE} failed: authentication error, check the gh-token secret"
      return 1
    fi
    if [[ ${attempt} -lt 3 ]]; then
      echo "Push attempt ${attempt} failed, retrying in $((attempt * 10))s"
      sleep $((attempt * 10))
    fi
  done
  echo "::error::Push to ${ORGANIZATION}/${PACKAGE} failed after 3 attempts"
  return 1
}

DIR_PWD=`pwd`

echo "Monorepo Split – ${PACKAGE}"

echo "Init environment"

PUSH_OPTS=""
if [[ "$FORCE" == true ]]; then
  PUSH_OPTS="${PUSH_OPTS} --force"
fi
if [[ "$PUSH_TAG" == true ]]; then
  PUSH_OPTS="${PUSH_OPTS} --tags"
fi

cd ${DIR_PWD}
echo "mkdir -p ${DIR_PWD}/${TMP}/${PACKAGE}"
mkdir -p ${DIR_PWD}/${TMP}/${PACKAGE}

echo "git clone --bare --no-local .git ${DIR_PWD}/${TMP}/${PACKAGE}"
git clone --bare --no-local .git ${DIR_PWD}/${TMP}/${PACKAGE}

echo "cd ${DIR_PWD}/${TMP}/${PACKAGE}"
cd ${DIR_PWD}/${TMP}/${PACKAGE}

echo "git filter-repo --subdirectory-filter packages/${PACKAGE}"
git filter-repo --subdirectory-filter packages/${PACKAGE}

echo "git push github.com/${ORGANIZATION}/${PACKAGE} ${BRANCH} --dry-run ${PUSH_OPTS} --verbose"
push_with_retry ${BRANCH} --dry-run ${PUSH_OPTS} --verbose

echo "git push github.com/${ORGANIZATION}/${PACKAGE} ${BRANCH} ${PUSH_OPTS} --verbose"
push_with_retry ${BRANCH} ${PUSH_OPTS} --verbose
