#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Ensure dependencies are present
if [[ ! -x $(which docker) ]]; then
    echo "[-] Dependencies unmet.  Please verify that the following are installed and in the PATH:  docker" >&2
    exit 1
fi

if [[ -e /root/bpftrace ]]; then
  echo "bpftrace has been downloaded already, if you want to download a new version"
  echo "delete the current one at /root/bpftrace"
  /root/bpftrace -V
  exit 0
fi

echo "Changing directory to /root/"
cd /root/
echo "Downloading bpftrace using docker (you need to be able to run docker commands)"
# see https://github.com/iovisor/bpftrace/blob/master/INSTALL.md#copying-bpftrace-binary-from-docker
docker run --rm -v $(pwd):/output quay.io/iovisor/bpftrace:master-vanilla_llvm_clang_glibc2.23 /bin/bash -c "cp /usr/bin/bpftrace /output"
chmod 0755 bpftrace
echo "Downloading testing bpftrace, will only work on linux with glibc 2.23+"
./bpftrace -V
echo "Deleting docker image since the same tag is reused"
docker rmi quay.io/iovisor/bpftrace:master-vanilla_llvm_clang_glibc2.23
echo "Returning to previous directory"
cd -
