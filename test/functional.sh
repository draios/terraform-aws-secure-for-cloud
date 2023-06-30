#!/usr/bin/env bash

set -e

MOTO_VERSION=4.1.12
MOTO_CONTAINER=motoserver
test -n "${EXAMPLES}" || EXAMPLES=$(find examples -type f -name main.tf)

function cleanup() {
  printf "removing container: "
  docker rm -f ${MOTO_CONTAINER}
}
trap cleanup EXIT

docker run --detach --name ${MOTO_CONTAINER} -p 5000:5000 motoserver/moto:${MOTO_VERSION}

for example in ${EXAMPLES} ; do
  printf "functional testing ${example}\n"
  example_dir="$(dirname ${example})"
  test -d "${example_dir}" || (printf "not an example directory: ${example_dir}\n" ; exit 1)
  git clean -fxd "${example_dir}"
  pushd "${example_dir}"
    terraform init
    terraform validate
    terraform apply --auto-approve
    terraform apply --auto-approve --destroy
  popd
done
