#pytemplate for running a few things on windows
import os, os.path
import pandas as pd
import shutil


##  SOME DIRECTORIES AND FILE PATHS

#get current directory
file = "C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-01-15\\user-files\\cri2016rand\\cri2016rand_test\\ieem_exp_design.csv"
dir_cur = os.path.dirname(os.path.realpath(file))
os.chdir(dir_cur)
#set base command
#fpw_gams = "C:\\GAMS\\win64\\30.3\\gams.exe"
fpw_gams = "C:\\GAMS\\win64\\25.1\\gams.exe"

#file path for experimental design
fp_csv_exp_design = os.path.join(dir_cur, "ieem_exp_design.csv")

#get experimental design
df_ed = pd.read_csv(fp_csv_exp_design)

#all runs
all_runs = list(df_ed["run_id"].unique())
all_runs.sort()

header = "\n" + "#"*30 + "\n"
#loop over runs to run data file and simulation gdx
for run in all_runs:
	# run= 1, for testing
	print(header)
	print("###   STARTING RUN = " + str(run))
	print(header)

	#set file paths
	fn_gms_dat = "data_" + str(run) + ".gms"
	fn_gms_tmp = "tmpsim_" + str(run) + ".gms"
	#check for existence
	if os.path.exists(fn_gms_dat) and os.path.exists(fn_gms_tmp):
		#build command for data
		comm = (fpw_gams + " %s s=save_%s\data --NonIMv2=1")%(fn_gms_dat, run)
		print("\tSending command:\n\t\t" + comm)
		os.system(comm)
		print("")
		#build command for sim
		comm = (fpw_gams + " %s")%(fn_gms_tmp)
		print("\tSending command:\n\t\t" + comm)
		os.system(comm)

	else:
		print("\n###   data.gms FOR SCENARIO %s NOT FOUND. SKIPPING...   ###\n"%(run))

	print("###   RUN " + str(run) + " COMPLETE.")
	print(header)
	print("\n"*5)
		
