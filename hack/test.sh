#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
# set -o xtrace

./hack/build.sh

for example in examples/* ; do
  echo $example
  (
    cd "${example}"
    ../../out/ytt-test.sh
  )
done
