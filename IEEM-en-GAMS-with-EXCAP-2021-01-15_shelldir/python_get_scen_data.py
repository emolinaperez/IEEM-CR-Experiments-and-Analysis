import os, os.path
import numpy as np
import pandas as pd
import sys
import shutil

#function to build dictionaries
def build_dict(df_in):return dict([tuple(df_in.iloc[i]) for i in range(len(df_in))])

##  DIRECTORIES

#get current directory
file =  "C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-01-15\\user-files\\cri2016rand\\Calib Runs 2021-02-24\\"
dir_cur = os.path.dirname(os.path.realpath(file))
#set app name
name_app = "cri2016rand"
#set the working directory
dir_win = "C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-01-25"
#directories for other files
dir_save = os.path.join(dir_win, "save")
dir_uf = os.path.join(dir_win, "user-files", name_app)


###   FILE PATHS

##  MAC SIDE

#file path for experimental design
fp_csv_exp_design = os.path.join(dir_win, "ieem_exp_design.csv")
#file paths for files to read in/replace
fp_gms_data = os.path.join(dir_win, "data.gms")
fp_gms_sim = os.path.join(dir_win, "sim.gms")
fp_gms_repbaseyr = os.path.join(dir_win, "repbaseyr.gms")
fp_gms_repenviro = os.path.join(dir_win, "repenviro.gms")
fp_gms_reppov = os.path.join(dir_win, "reppov.gms")

#file path for gams include files
fp_inc_data = os.path.join(dir_uf, ("##APP##-data2.inc").replace("##APP##", name_app))
fp_inc_sim = os.path.join(dir_uf, ("##APP##-sim.inc").replace("##APP##", name_app))
fp_inc_sim2 = os.path.join(dir_uf, ("##APP##-sim2.inc").replace("##APP##", name_app))
#python scripts
fp_py_run_gdxxrw = os.path.join(dir_cur, "python_run_gdxxrw.py")


##  WINDOWS SIDE

#some windows paths
dirw_win_home = "C:\\Users\\jsyme"
dirw_win = dirw_win_home + "\\Documents\\Projects\\SWCHE093-1000\\IEEM-en-GAMS-with-EXCAP-2021-01-15"
dirw_uf = dirw_win + "\\user-files\\##APP##".replace("##APP##", name_app)
#some windows file paths
fpw_gms_data = dirw_win + "\\" + os.path.basename(fp_gms_data)
fpw_inc_data = dirw_uf + "\\" + os.path.basename(fp_inc_data)
fpw_inc_sim = dirw_uf + "\\" + os.path.basename(fp_inc_sim)

#set some default commands
cmd_prlctrl = "prlctl exec \"syme-j-PVM\" cmd /c \"##CMDAPP## ##CMDSCRIPT##\""
cmd_winpy = "C:\\Users\\jsyme\\AppData\\Local\\Programs\\Python\\Python37\\python.exe"
cmd_wingams = "C:\\GAMS\\win64\\30.3\\gams.exe"


########################
#    INITIALIZATION    #
########################

##  EXPERIMENTAL DESIGN

#get experimental design
df_exp_design = pd.read_csv(fp_csv_exp_design)
df_exp_design = df_exp_design.sort_values(by = ["run_id"]).reset_index(drop = True)
#build dictionaries
dict_scen_to_dat = build_dict(df_exp_design[["run_id", "data"]])
dict_scen_to_sim = build_dict(df_exp_design[["run_id", "sim"]])
#all runs
all_runs = list(df_exp_design["run_id"])


##  DIRECTORIES FOR MOVING FROM WIN TO LINUX FS

#all subdirectories
all_subdirs = [x for x in os.listdir(dir_win) if ("." not in x)]
all_dirs_check = [(x + "\\") for x in all_subdirs]
#function for checking
def check_x(str_in, paths):
    check_q = False
    for p in paths:
        if p in str_in:
            check_q = True
    return check_q


##  READ IN FILES

dict_fps_in = {
	"data": fp_gms_data,
	"sim": fp_gms_sim,
	"inc_dat": fp_inc_data,
	"inc_sim": fp_inc_sim,
	"inc_sim2": fp_inc_sim2,
	"repbaseyr": fp_gms_repbaseyr,
	"repenviro": fp_gms_repenviro,
	"reppov": fp_gms_reppov
}

dict_strs_in = {}
#loop to readlines
for fshort in dict_fps_in.keys():
	f_tmp = open(dict_fps_in[fshort], "r")
	str_tmp = f_tmp.readlines()
	f_tmp.close()
	#add to dictionary
	dict_strs_in[fshort] = str_tmp


##  CLEAN FILES THAT NEED TO BE CLEANED

#output dictionary mapping file paths to clean to their output paths
all_fp_clean = [fp_gms_sim, fp_inc_sim]
#add to dictionary
dict_output_clean = {}

#loop over files to export linux versions
for fp in all_fp_clean:

	print("#"*30 + "\nStarting file " + os.path.basename(fp) + "...")

	fp_out = fp.replace(dir_win, dir_cur)

	#read from the windows side
	f_read = open(fp, "r")
	rl = f_read.readlines()
	f_read.close()

	rl_new = []
	#range over the lines
	for i in range(len(rl)):
		x = str(rl[i])
		if check_x(x, all_dirs_check):
			print(i)
			x = x.split(" ")
			x_new = ""

			for k in range(len(x)):
				x_sub = x[k]

				if check_x(x_sub, all_dirs_check):
					x_sub_new = x_sub.replace("\\", "/")
				else:
					x_sub_new = x_sub

				if len(x_new) == 0:
					x_new = x_sub_new
				else:
					x_new = x_new + " " + x_sub_new

			rl_new.append(x_new)

		else:
			rl_new.append(x)

	#export to the mac side
	f_write = open(fp_out, "w")
	f_write.writelines(rl_new)
	f_write.close()

	#set output key
	key_out = os.path.basename(fp)
	dict_output_clean.update({key_out: rl_new})



#############################
#    LOOP OVER SCENARIOS    #
#############################

dict_scen_repl = {
	"data": {
		"GDXXRW user-files\\%app%\\%app%-data.xlsx index=layout!A1": ("GDXXRW " + dirw_win + "\\user-files\\%app%\\%app%-##DATASCEN##.xlsx index=layout!A1"),
		"$GDXIN %app%-data.gdx": ("$GDXIN %app%-##DATASCEN##.gdx"),
		"$IF %NonIMv2%==1 $IF EXIST user-files\%app%\%app%-data2.inc $INCLUDE user-files\%app%\%app%-data2.inc": ("$IF %NonIMv2%==1 $IF EXIST   user-files\%app%\%app%-data2_##RUNID##.inc $INCLUDE user-files\%app%\%app%-data2_##RUNID##.inc")
	},
	"inc_dat": {
		"GDXXRW user-files\\cri2016rand\\cri2016rand-data.xlsx index=layout-EXTRA!A1": ("GDXXRW " + dirw_win + "\\user-files\\cri2016rand\\cri2016rand-##DATASCEN##.xlsx index=layout-EXTRA!A1"),
		"$GDXIN cri2016rand-data.gdx": "$GDXIN cri2016rand-##DATASCEN##.gdx"
	},
	"inc_sim": {
		"$CALL GDXXRW user-files\%app%\%app%-sim.xlsx": "*$CALL GDXXRW user-files/%app%/%app%-##SIMSCEN##.xlsx",
		"$GDXIN %app%-sim.gdx": "$GDXIN %app%-##SIMSCEN##.gdx"
	},
	"inc_sim2": {
		"EXECUTE_LOADDC 'cri2016rand-sim.gdx',": "EXECUTE_LOADDC 'cri2016rand-##SIMSCEN##.gdx',"
	},
	#simulation file should use the linux file paths
	"sim": {
		"$IF %NonIMv2%==1 $IF EXIST user-files/%app%/%app%-sim.inc $INCLUDE user-files/%app%/%app%-sim.inc": "$IF %NonIMv2%==1 $IF EXIST user-files/%app%/%app%-sim_##RUNID##.inc $INCLUDE user-files/%app%/%app%-sim_##RUNID##.inc",
		"$IF EXIST user-files/%app%/%app%-sim2.inc $INCLUDE user-files/%app%/%app%-sim2.inc": "$IF EXIST user-files/%app%/%app%-sim2_##RUNID##.inc $INCLUDE user-files/%app%/%app%-sim2_##RUNID##.inc"
	},
	#repbaseyr
	"repbaseyr": {
		"$IF %NonIMv2%==1 EXECUTE_UNLOAD 'repbaseyr2-%app%.gdx',": "*$IF %NonIMv2%==1 EXECUTE_UNLOAD 'repbaseyr2-%app%.gdx',"
	},
	#repenviro
	"repenviro": {
		"$IF %NonIMv2%==1 EXECUTE_UNLOAD 'repenviro2-%app%.gdx',": "*$IF %NonIMv2%==1 EXECUTE_UNLOAD 'repenviro2-%app%.gdx',"
	},
	#reppov
	"reppov": {
		"$IF %NonIMv2%==1 EXECUTE_UNLOAD 'reppov2-%app%.gdx',": "*$IF %NonIMv2%==1 EXECUTE_UNLOAD 'reppov2-%app%.gdx',"
	}
}
print("HERE")
header = "\n" + "#"*30 + "\n"
#function for replacing lines
def do_repl(str_in, dict_in, dict_scen):
	#loop to update with the scenario
	for k in dict_in.keys():
		new_str = dict_in[k]
		for sk in dict_scen.keys():
			new_str = new_str.replace(sk, dict_scen[sk])
		dict_in.update({k: new_str})
		#print("\tnew_str for " + str(k) + ": " + new_str)
		#print("\t##DATASCEN## in new_str?\t" + str("##DATASCEN##" in new_str))

	str_out = str_in.copy()
	#loop to replace
	for i in range(len(str_out)):
		line = str(str_out[i])
		for k in dict_in.keys():
			#check if our replacement string is contained in this line
			if str(k) in line:
				#if so, update
				line = line.replace(k, dict_in[k])
		#update string list
		str_out[i] = line

	return str_out


#loop over scenarios
for scen in all_runs:
	print(header)
	print("Starting data scenario: '" + str(scen) + "'...")

	#get data and sim
	scen_dat = "data_" + str(dict_scen_to_dat[scen])
	scen_sim = "sim_" + str(dict_scen_to_sim[scen])

	#update the file path save
	dir_save_scen = dir_save.replace("save", "save_" + str(scen))
	#make dirs
	if os.path.exists(dir_save_scen):
		shutil.rmtree(dir_save_scen)
	#create the new save directory
	os.makedirs(dir_save_scen, exist_ok = True)


	##  EXPORT THE DATA INCLUDE FILE

	print("\Exporting dim.inc...")
	str_inc_dat_scen = dict_strs_in["inc_dat"].copy()
	#copy the dictionary
	dict_r_inc_dat = dict_scen_repl["inc_dat"].copy()
	#set the
	str_inc_dat_scen = do_repl(str_inc_dat_scen, dict_r_inc_dat, {"##DATASCEN##": scen_dat})
	#write to new file
	fp_new = fp_inc_data.replace(".inc", "_" + str(scen) + ".inc")
	f_new = open(fp_new, "w")
	f_new.writelines(str_inc_dat_scen)
	f_new.close()


	##  EXPORT DATA.GMS AND RUN FOR EACH SCENARIO

	print("\tExporting data.gms...")
	str_data_scen = dict_strs_in["data"].copy()
	#copy the dictionary
	dict_r_dat = dict_scen_repl["data"].copy()
	#set the data file out
	str_data_scen = do_repl(str_data_scen, dict_r_dat, {"##DATASCEN##": scen_dat, "##RUNID##": str(scen)})
	#write to new file
	fp_new = fp_gms_data.replace(".gms", "_" + str(scen) + ".gms")
	f_new = open(fp_new, "w")
	f_new.writelines(str_data_scen)
	f_new.close()
	#set windows path
	fpw_new = fpw_gms_data.replace(".gms", "_" + str(scen) + ".gms")
	dirw_save_scen = dir_save_scen.replace(dir_win, dirw_win).replace("/", "\\")

	#build windows command
	comm = cmd_prlctrl.replace("##CMDAPP##", cmd_wingams)
	comm = comm.replace("##CMDSCRIPT##", fpw_new + " s=" + dirw_save_scen + "\\data --NonIMv2=1")
	#notify
	print("Sending command:\n\t" + comm)
	#run gams
	#os.system(comm)


	##  CALL THE GDXXRW FOR SIM

	print("\tCalling sim GDXXRW...")
	#use simulation (it's only one line) -- windows code to send via prlctl
	sim_gams_call = "$CALL GDXXRW user-files\\cri2016rand\\cri2016rand-##SIMSCEN##.xlsx index=layout!A1\n".replace("##SIMSCEN##", scen_sim)
	#set temporary file path out
	fn_tmp = "tmpsim_" + str(scen) + ".gms"
	fp_tmp = os.path.join(dir_win, fn_tmp)

	if os.path.exists(fp_tmp):
		os.remove(fp_tmp)
	fpw_tmp = dirw_win + "\\" + fn_tmp
	#write to temporary file
	f_tmp = open(fp_tmp, "w")
	f_tmp.writelines(sim_gams_call)
	f_tmp.close()

	#build windows command
	comm = cmd_prlctrl.replace("##CMDAPP##", cmd_wingams)
	comm = comm.replace("##CMDSCRIPT##", fpw_tmp)
	#notify
	print("Sending command:\n\t" + comm)
	#run gams
	#os.system(comm)


	##  EXPORT THE SIM.INC

	print("\Exporting sim.inc...")
	str_inc_sim_scen = dict_strs_in["inc_sim"].copy()
	#copy the dictionary
	dict_r_inc_sim = dict_scen_repl["inc_sim"].copy()
	#set the
	str_inc_sim_scen = do_repl(str_inc_sim_scen, dict_r_inc_sim, {"##SIMSCEN##": scen_sim})
	#write to new file
	fp_new = fp_inc_sim.replace(".inc", "_" + str(scen) + ".inc")
	f_new = open(fp_new, "w")
	f_new.writelines(str_inc_sim_scen)
	f_new.close()


	##  EXPORT THE SIM2.INC

	print("\Exporting sim2.inc...")
	str_inc_sim2_scen = dict_strs_in["inc_sim2"].copy()
	#copy the dictionary
	dict_r_inc_sim2 = dict_scen_repl["inc_sim2"].copy()
	#set the
	str_inc_sim2_scen = do_repl(str_inc_sim2_scen, dict_r_inc_sim2, {"##SIMSCEN##": scen_sim})
	#write to new file
	fp_new = fp_inc_sim2.replace(".inc", "_" + str(scen) + ".inc")
	f_new = open(fp_new, "w")
	f_new.writelines(str_inc_sim2_scen)
	f_new.close()


	##  BUILD AND EXPORT SIM.GMS LOCALLY

	print("\tBuilding sim.gms...")
	str_sim_scen = dict_output_clean["sim.gms"].copy()
	#copy the dictionary
	dict_r_sim = dict_scen_repl["sim"].copy()
	#update the string
	str_sim_scen = do_repl(str_sim_scen, dict_r_sim, {"##RUNID##": str(scen)})
	#set output file path
	fp_gms_sim_out = fp_gms_sim.replace(dir_win, dir_cur).replace(".gms", "_" + str(scen) + ".gms")
	#write
	f_new = open(fp_gms_sim_out, "w")
	f_new.writelines(str_sim_scen)
	f_new.close()

	print("Data scenario: '" + str(scen) + "' complete.")
	print(header)


##  CLEAN REP.GMS FILES ONCE

if False:
	for fn in ["repbaseyr", "repenviro", "reppov"]:

		print("\Cleaning %s.gms..."%(fn))
		str_gms_rep = dict_strs_in[fn].copy()
		#copy the dictionary
		dict_r_gms_rep = dict_scen_repl[fn].copy()
		#update the string
		str_gms_rep = do_repl(str_gms_rep, dict_r_gms_rep, {})
		#set output file path
		fp_gms_rep_out = dict_fps_in[fn].replace(dir_win, dir_cur)
		#write
		f_new = open(fp_gms_rep_out, "w")
		f_new.writelines(str_gms_rep)
		f_new.close()



#####################################
#    COPY PY SCRIPT OVER AND RUN    #
#####################################

print("Copying " + os.path.basename(fp_py_run_gdxxrw) + " to Parallels and running...")
#copy over
shutil.copyfile(fp_py_run_gdxxrw, fp_py_run_gdxxrw.replace(dir_cur, dir_win))
#build prlctl command
comm = cmd_prlctrl.replace("##CMDAPP##", cmd_winpy)
comm = comm.replace("##CMDSCRIPT##", dirw_win + "\\" + os.path.basename(fp_py_run_gdxxrw))
#notify
#print("Sending command:\n\t" + comm)
#run gams
#os.system(comm)
