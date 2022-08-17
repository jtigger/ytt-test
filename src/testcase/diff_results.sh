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
