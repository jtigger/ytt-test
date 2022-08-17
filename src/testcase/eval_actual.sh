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
