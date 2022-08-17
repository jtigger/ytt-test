(@- load("@ytt:data", "data") -@)
#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
#set -o xtrace

SCHEMA_YAML=$(cat << EOF
(@= data.read("/testcase/schema.yaml") -@)
EOF
)
TEST_CFG_STAR=$(cat << EOF
(@= data.read("/testcase/test_cfg.star") -@)
EOF
)
EVAL_ACTUAL_SH=$(cat << EOF
(@= data.read("/testcase/eval_actual.sh") -@)
EOF
)
EVAL_EXPECTED_SH=$(cat << EOF
(@= data.read("/testcase/eval_expected.sh") -@)
EOF
)
DIFF_RESULTS_SH=$(cat << EOF
(@= data.read("/testcase/diff_results.sh") -@)
EOF
)

# At this time, file marks do not match on file renames, so the .txt suffix is required to treat them as text templates.
#  $1 = directory to find the .txt files
function hack_remove_txt_extension_from_scripts_in() {
  for txt_file in "${1}"/*.txt ; do
    mv "${txt_file}" "${txt_file%.txt}"
  done
}

#
# Execution begins here
#
TESTS_OUT_DIR=.ytt-test-out

if [[ -d "${TESTS_OUT_DIR}" ]]; then
  rm -rf "${TESTS_OUT_DIR}"
fi
mkdir "${TESTS_OUT_DIR}"

ytt_tests_root=".ytt-tests"
tests_to_run=$( find ${ytt_tests_root} -name "*.test.yaml" )
export YTT_SUBJECT=${PWD}

overall_result=0
for test_file in ${tests_to_run}; do
  test_name=$( echo "${test_file}" | sed "s|^${ytt_tests_root}/||" | sed "s|.test.yaml$||" | sed "s|/|__|g" )
  test_dir=$( dirname "${test_file}" )
  out_dir="${YTT_SUBJECT}/${TESTS_OUT_DIR}/${test_name}"
  cmd_dir="${out_dir}/cmd"

  # customize scripts for _this_ use-case.
  ytt -f schema.yaml=<(echo "${SCHEMA_YAML}") \
      -f test_cfg.star=<(echo "${TEST_CFG_STAR}") \
      -f eval_actual.sh.txt=<(echo "${EVAL_ACTUAL_SH}") \
      -f eval_expected.sh.txt=<(echo "${EVAL_EXPECTED_SH}") \
      -f diff_results.sh.txt=<(echo "${DIFF_RESULTS_SH}") \
      --data-values-file ${test_file} \
      --data-value _ytt_test_.test_file="${test_file}" \
      --data-value _ytt_test_.out_dir="${out_dir}" \
      --dangerous-emptied-output-directory="${cmd_dir}" >/dev/null

  hack_remove_txt_extension_from_scripts_in "${cmd_dir}"

  (
    cd "${test_dir}"
    source "${cmd_dir}/eval_actual.sh"
    source "${cmd_dir}/eval_expected.sh"
    source "${cmd_dir}/diff_results.sh"
  )

done

# TODO: make this an explicit return value from diff_results.sh somehow.
if [[ $overall_result -ne 0 ]]; then
	echo "FAILURE"
	exit 1
fi

echo "SUCCESS"
