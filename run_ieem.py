import os, os.path
import shutil
import pandas as pd

#set the working directory
dir_cur = os.path.dirname(os.path.realpath(__file__))
dir_mod = "/home/RAND.ORG/jsyme/IEEM-en-GAMS-with-EXCAP-2021-01-15"
os.chdir(dir_mod)
#get

#file path for experimental design
fp_csv_exp_design = os.path.join(dir_mod, "ieem_exp_design.csv")

##  EXPERIMENTAL DESIGN

#get experimental design
df_exp_design = pd.read_csv(fp_csv_exp_design)
df_exp_design = df_exp_design.sort_values(by = ["run_id"]).reset_index(drop = True)
#all runs
all_runs = list(df_exp_design["run_id"])



##   LOOPS

coms = ["mod", "sim", "rep", "repbaseyr", "repmacro", "repmeso", "repenviro", "reppov"]
header = "#"*30 + "\n"

def get_gdx():
	ag = [x for x in os.listdir(dir_mod) if ".gdx" in x]
	ag = [x for x in ag if (x[-4:] == ".gdx")]
	return set(ag)

#initialize set of current gdx files
all_gdx = get_gdx()

for r in all_runs:
	#notify
	print("#"*30 + "\n###\n" + "###   STARTING run_id = " + str(r) + "\n###\n" + "#"*30 + "\n")
	#set the previous command
	prev = "data"

	for i in range(len(coms)):

		cur_coms = "%s_%s"%(coms[i], r)
		#check if scenario-dependent path exists
		if not os.path.exists(cur_coms + ".gms"):
			cur_coms = str(coms[i])

		comm = cur_coms + " r=save_" + str(r) + "/" + prev + " s=save_" + str(r) + "/" + cur_coms + " FW=1"
		comm = "gams " + comm
		#if i == (len(coms) - 1):
		#	comm = comm + " pw=120 gdx=" + cur_coms
		#update the previous
		prev = cur_coms
		print(header)
		print("\nSending:\n\t'" + comm + "'...")
		#run the command
		os.system(comm)
		#check gdx names
		all_gdx_cur = get_gdx()
		#get new file
		new_gdx = list(all_gdx_cur - all_gdx)
		for fg in new_gdx:
			fp_old = os.path.join(dir_mod, fg)
			fp_new = os.path.join(dir_mod, fg.replace(".gdx", "_run-" + str(r) + ".gdx"))
			os.rename(fp_old, fp_new)
			#notify
			print("\tRenamed '%s' to '%s'"%(os.path.basename(fp_old), os.path.basename(fp_new)))
		#update at each iteration (include updated name)
		all_gdx = get_gdx()
		#notify
		print("Model " + cur_coms + " done.\n\n")

	#check for gdx files to delete
	fns_rm =[x for x in os.listdir(dir_mod) if (x[-4:] == ".lst")]
	fns_rm = fns_rm + [x for x in os.listdir(dir_mod) if (x[-4:] == ".gdx") and (("reppov" in x) or ("repenviro" in x) or ("repbaseyr" in x))]
	fns_rm = fns_rm + ["report-cri2016rand_run-" + str(r) + ".gdx"]

	#loop to remove
	for fn in fns_rm:
		fn_rm = os.path.join(dir_mod, fn)
		print("\tRemoving " + fn_rm + "...")
		os.remove(fn_rm)
	#update gdx files to account for lost report file
	all_gdx = get_gdx()

	fp_rm = os.path.join(dir_mod, "save_" + str(r))
	#remove the save directory
	if os.path.exists(fp_rm):
		print("Removing path '" + fp_rm + "'...")
		shutil.rmtree(fp_rm)
		print("\n")

	print("\n\n" + "#"*30 + "\n###\n###   RUN run_id = " + str(r) + " COMPLETE.\n###\n" + "#"*30 + "\n"*3)

#checkstring
excl_strings = ["cri2016rand_data-", "cri2016rand_sim-"]

#collect results
all_copy = [x for x in os.listdir() if (x[-4:] == ".gdx")]
for es in excl_strings:
	n = len(es)
	all_copy = [x for x in all_copy if (x[0:min(n, len(x))] != es)]
print("all_copy:\n" + (("\t- %s\n"*(len(all_copy)))%tuple(all_copy)))
all_copy = all_copy + [os.path.basename(fp_csv_exp_design)]
#create temporary file
tmp_dir = "ieem_results"

if os.path.exists(tmp_dir):
	shutil.rmtree(tmp_dir)
#create
os.makedirs(tmp_dir, exist_ok = True)

print(header)
print("\nMoving GDX files...")
#then, copy in
for fn in all_copy:
	com = "mv " + fn + " " + os.path.join(tmp_dir, fn)
	print("\nSending:\n\t'" + com + "'...")
	os.system(com)
#then, create tarball
comm_targz = "COPYFILE_DISABLE=1 tar -cvzf ieem_model_results.tar.gz " + tmp_dir + "/"
print("\nSending:\n\t'" + comm_targz + "'...")
os.system(comm_targz)
print("Successfully created tar gz. Removing temporary directory...")

#delete the temporary directory
shutil.rmtree(tmp_dir)
