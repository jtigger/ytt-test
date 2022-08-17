#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
#set -o xtrace

SCHEMA_YAML=$(cat << EOF
#@ load("@ytt:assert", "assert")
#@ expects=["expected", "expected_out", "expected_err"]

#@data/values-schema
#@schema/validation ("one of " + ", ".join(expects), assert.one_not_null(expects))
---
#@schema/desc "ytt invocation to test"
actual: ""

#@schema/desc "ytt invocation describing the expected results"
#@schema/nullable
expected: ""

#@schema/desc "Expect the given output to standard output."
#@schema/nullable
expected_out: ""

#@schema/desc "Expect the given output to standard error."
#@schema/nullable
expected_err: ""

#@schema/desc "Values derived by ytt test itself."
_ytt_test_:
  #@schema/desc "Path to the test spec (this file)."
  test_file: ""
  #@schema/desc "Absolute path to the current test base directory"
  out_dir: ""
EOF
)
TEST_CFG_STAR=$(cat << EOF
load("@ytt:data", "data")
load("@ytt:struct", "struct")

d = {}
d["out_dir"] = data.values._ytt_test_.out_dir
d["test_file"] = data.values._ytt_test_.test_file
d["actual"]={}
d["actual"]["dir"]=data.values._ytt_test_.out_dir + "/actual"
d["actual"]["result_dir"]=d["actual"]["dir"] + "/result"
d["actual"]["std"]={}
d["actual"]["std"]["dir"]=d["actual"]["dir"] + "/std"
d["actual"]["std"]["out_txt"]=d["actual"]["std"]["dir"]+ "/out.txt"
d["actual"]["std"]["err_txt"]=d["actual"]["std"]["dir"]+ "/err.txt"
d["expected"]={}
d["expected"]["dir"]=data.values._ytt_test_.out_dir + "/expected"
d["expected"]["result_dir"]=d["expected"]["dir"] + "/result"
d["expected"]["std"]={}
d["expected"]["std"]["dir"]=d["expected"]["dir"] + "/std"
d["expected"]["std"]["out_txt"]=d["expected"]["std"]["dir"]+ "/out.txt"
d["expected"]["std"]["err_txt"]=d["expected"]["std"]["dir"]+ "/err.txt"

dirs=struct.encode(d)
EOF
)
EVAL_ACTUAL_SH=$(cat << EOF
(@-
load("@ytt:data", "data"); spec=data.values
load("test_cfg.star", "dirs")

args = {}
args["std_dir"]=dirs.actual.std.dir
args["result_dir"]=dirs.actual.result_dir
args["cmd"]=spec.actual.rstrip("\n")     # to allow additional flags to be added
args["output"]=""
args["stdout_path"]=dirs.actual.std.out_txt
args["stderr_path"]=dirs.actual.std.err_txt

if spec.expected != None:
  args["output"]=" --dangerous-emptied-output-directory='{result_dir}'".format(**args)
end
# otherwise, output is captured by stdout.

script='''#!/usr/bin/env bash
mkdir -p '{std_dir}'
mkdir -p '{result_dir}'

{cmd} {output} --debug >'{stdout_path}' 2>'{stderr_path}'
'''
-@)
(@= script.format(**args) @)
EOF
)
EVAL_EXPECTED_SH=$(cat << EOF
(@-
load("@ytt:data", "data"); spec=data.values
load("test_cfg.star", "dirs")

if spec.expected != None:
  args = {}
  args["std_dir"]=dirs.expected.std.dir
  args["result_dir"]=dirs.expected.result_dir
  args["cmd"]=spec.expected.rstrip("\n")     # to allow additional flags to be added
  args["output"]=" --dangerous-emptied-output-directory='{result_dir}'".format(**args)
  args["stdout_path"]=dirs.expected.std.out_txt
  args["stderr_path"]=dirs.expected.std.err_txt
  script='''#!/usr/bin/env bash
mkdir -p '{std_dir}'
mkdir -p '{result_dir}'

{cmd} {output} --debug >'{stdout_path}' 2>'{stderr_path}'
'''
elif spec.expected_out != None:
  args = {}
  args["std_dir"]=dirs.expected.std.dir
  args["stdout_path"]=dirs.expected.std.out_txt
  args["stdout"]=spec.expected_out

  script='''#!/usr/bin/env bash
mkdir -p '{std_dir}'

echo "{stdout}" >'{stdout_path}'
'''
elif spec.expected_err != None:
  args = {}
  args["std_dir"]=dirs.expected.std.dir
  args["stderr_path"]=dirs.expected.std.err_txt
  args["stderr"]=spec.expected_err

  script='''#!/usr/bin/env bash
mkdir -p '{std_dir}'

echo "{stderr}" >'{stderr_path}'
'''
end

-@)
(@= script.format(**args) @)
EOF
)
DIFF_RESULTS_SH=$(cat << EOF
(@-
load("@ytt:data", "data"); spec=data.values
load("test_cfg.star", "dirs")

args={}
args["out_dir"]=dirs.out_dir
args["test_file"]=spec._ytt_test_.test_file
args["actual"]=""
args["expected"]=""
args["diff_file"]=""

if spec.expected != None:
  args["actual"]=dirs.actual.result_dir
  args["expected"]=dirs.expected.result_dir
  args["diff_file"]=dirs.out_dir + "/results.diff"
elif spec.expected_out != None:
  args["actual"]=dirs.actual.std.out_txt
  args["expected"]=dirs.expected.std.out_txt
  args["diff_file"]=dirs.out_dir + "/stdout.diff"
elif spec.expected_err != None:
  args["actual"]=dirs.actual.std.err_txt
  args["expected"]=dirs.expected.std.err_txt
  args["diff_file"]=dirs.out_dir + "/stderr.diff"
end
script='''
set +e
  diff --recursive "{actual}" "{expected}" >"{diff_file}"
set -e
if [[ -s "{diff_file}" ]]; then
  echo -e "fail\t{test_file}"
  echo -e "\t\t==> {diff_file}\n"
  overall_result=1
else
  echo -e "pass\t{test_file}"
fi
'''
-@)
(@= script.format(**args) -@)
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
