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
