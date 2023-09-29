#!/bin/bash

# exit and report the failure if any command fails
exit_trap () {
  local lc="$BASH_COMMAND" rc=$?
  echo "Command [$lc] exited with code [$rc]"
}

trap exit_trap EXIT
set -ex

VERSION=${CMARK_VERSION:=0.29.0}
BASENAME="cmark-${VERSION}"
PREFIX="${PWD}/${BASENAME}"

[ -e Makefile ] && make realclean

printf "Building %s in %s\n" "${BASENAME}" "${PREFIX}"
curl -sL "https://github.com/jgm/cmark/archive/${VERSION}.tar.gz" | tar xz
(cd "${BASENAME}" && make INSTALL_PREFIX="${PREFIX}" install)

printf "Building and testing CommonMark\n"
perl Makefile.PL INC=-I"${PREFIX}/include" LIBS=-L"${PREFIX}/lib -lcmark"
make
make test TEST_VERBOSE=1
