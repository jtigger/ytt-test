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
