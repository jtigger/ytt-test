#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
set -o xtrace

ytt -f src/ \
    --file-mark 'ytt-test.sh:type=text-template' \
    --file-mark 'testcase/*:type=data' \
    --dangerous-emptied-output-directory=out

cp out/ytt-test.sh .
