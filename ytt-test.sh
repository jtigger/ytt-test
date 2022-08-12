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

overall_result=0
for test_spec in ${tests_to_run}; do
  test_name=$( echo "${test_spec}" | sed "s|^${ytt_tests_root}/||" | sed "s|.test.yaml$||" | sed "s|/|__|g" )
  test_dir=$( dirname "${test_spec}" )
  out_dir="${TESTS_OUT_DIR}/${test_name}"
	actual_dir="${out_dir}/actual"
	expected_dir="${out_dir}/expected"

CMD_YML=$(cat << EOF
#@ test_dir="${test_dir}"
#@ load("@ytt:data", "data")
#@ files = " ".join(["--file "+f for f in data.values.actual.subject.file])
#@ data_values = " ".join(["--data-values-file {}/{}".format(test_dir, f) for f in data.values.actual.fixtures["data-values-file"]])
--- #@ "ytt {} {}".format(files, data_values)
EOF
)

  YTT_CMD=$(ytt -f cmd.yml=<(echo "${CMD_YML}") --data-values-file ${test_spec})

  mkdir -p "${actual_dir}"
  ${YTT_CMD} --dangerous-emptied-output-directory="${actual_dir}" --debug >"${out_dir}/actual-ytt.stdout" 2>"${out_dir}/actual-ytt.stderr"

CMD_YML=$(cat << EOF
#@ test_dir="${test_dir}"
#@ load("@ytt:data", "data")
#@ files = " ".join(["--file "+f for f in data.values.expected.file])
--- #@ "ytt {}".format(files)
EOF
)
  YTT_CMD=$(ytt -f cmd.yml=<(echo "${CMD_YML}") --data-values-file ${test_spec})

  mkdir -p "${expected_dir}"
	expected_absdir="${PWD}"/"${expected_dir}"
	out_absdir="${PWD}"/"${out_dir}"

	(
		cd "${test_dir}"
		${YTT_CMD} --dangerous-emptied-output-directory="${expected_absdir}" --debug >"${out_absdir}/expected-ytt.stdout" 2>"${out_absdir}/expected-ytt.stderr"
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
