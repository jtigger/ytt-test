#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
#set -o xtrace

TESTS_OUT_DIR=.ytt-test-out

if [[ -d "${TESTS_OUT_DIR}" ]]; then
  rm -rf "${TESTS_OUT_DIR}"
fi
mkdir "${TESTS_OUT_DIR}"

ytt_tests_root=".ytt-tests"
tests_to_run=$( find ${ytt_tests_root} -name "*.test.yaml" )
export YTT_SUBJECT=${PWD}

overall_result=0
for test_spec in ${tests_to_run}; do
  test_name=$( echo "${test_spec}" | sed "s|^${ytt_tests_root}/||" | sed "s|.test.yaml$||" | sed "s|/|__|g" )
  test_dir=$( dirname "${test_spec}" )
  out_dir="${YTT_SUBJECT}/${TESTS_OUT_DIR}/${test_name}"
	actual_dir="${out_dir}/actual"
	expected_dir="${out_dir}/expected"

CMD_YML=$(cat << EOF
#@ load("@ytt:data", "data")
#@ args = {
#@   "cmd": data.values.actual,
#@   "stdout_path": "${out_dir}/actual-ytt.stdout",
#@   "stderr_path": "${out_dir}/actual-ytt.stderr",
#@   "result_dir": "${out_dir}/actual",
#@ }
--- #@ "{cmd} --dangerous-emptied-output-directory='{result_dir}' --debug >'{stdout_path}' 2>'{stderr_path}'".format(**args)
EOF
)

  YTT_CMD=$(ytt -f cmd.yml=<(echo "${CMD_YML}") --data-values-file ${test_spec})

  mkdir -p "${actual_dir}"
  (
    cd "${test_dir}"
    echo "${YTT_CMD}" >"${out_dir}/actual-ytt.cmdline"
    echo "${YTT_CMD}" | bash
  )

CMD_YML=$(cat << EOF
#@ load("@ytt:data", "data")
#@ args = {
#@   "cmd": data.values.expected,
#@   "stdout_path": "${out_dir}/expected-ytt.stdout",
#@   "stderr_path": "${out_dir}/expected-ytt.stderr",
#@   "result_dir": "${out_dir}/expected",
#@ }
--- #@ "{cmd} --dangerous-emptied-output-directory='{result_dir}' --debug >'{stdout_path}' 2>'{stderr_path}'".format(**args)
EOF
)

  YTT_CMD=$(ytt -f cmd.yml=<(echo "${CMD_YML}") --data-values-file ${test_spec})

  mkdir -p "${expected_dir}"
  (
    cd "${test_dir}"
    echo "${YTT_CMD}" >"${out_dir}/expected-ytt.cmdline"
    echo "${YTT_CMD}" | bash
  )
	
	diff_file="${out_dir}/result.diff"
  set +e
	  diff --recursive "${actual_dir}" "${expected_dir}" >"${diff_file}"
	set -e
	if [[ -s "${diff_file}" ]]; then
		echo -e "fail\t${test_spec}"
		echo -e "\t\t==> ${diff_file}\n"
		overall_result=1
	else
		echo -e "pass\t${test_spec}"
	fi
done

if [[ $overall_result -ne 0 ]]; then
	echo "FAILURE"
	exit 1
fi

echo "SUCCESS"
