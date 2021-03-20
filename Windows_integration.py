#===========================================================================================
# PART 1: TRANSFORM THE EXPERIMENTAL DESIGN INTO NEW FILES FOR RUNNING AND CREATE EXPERIMENTAL DESIGN TABLE
#===========================================================================================

import os, os.path
import shutil
import pandas as pd

## root directory
root = "C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-01-15\\"

##  SET THE NAME OF THE RUNS (CALIBRATION) PACKAGE HERE
nm_files_in = "user-files\\cri2016rand\\Calib Runs 2021-02-27"

## FULL PATH OF RUN PACKAGE
dir_files_in = os.path.join(root, nm_files_in)

#all excel files
all_runs = [int(x.replace("r", "")) for x in os.listdir(dir_files_in) if ("." not in x) and (x[0] == "r")]
all_runs.sort()

#set directories to copy into
nm_files_out = "user-files\\cri2016rand\\test"
dir_cp_mac = os.path.join(root, nm_files_out )

df_ed = []
#loop
for r in all_runs:
    #r= 1
    r_str = "r" + str(r)
    dir_cur = os.path.join(dir_files_in, r_str)
    #get file names
    fn_xlsx = [x for x in os.listdir(dir_cur)]

    fn_dat = [x for x in fn_xlsx if "-data" in x]
    fn_sim = [x for x in fn_xlsx if "-sim" in x]

    if min(len(fn_dat), len(fn_sim)) == 0:

        print("\n\tIssue with run number " + str(r) + "\n")

    else:
        #data file names
        fn_dat = fn_dat[0]
        fn_sim = fn_sim[0]
        #new names
        fn_dat_new = fn_dat.replace("-data", "-data_d" + str(r)).replace("new_", "")
        fn_sim_new = fn_sim.replace("-sim", "-sim_s" + str(r)).replace("new_", "")
        #get scenarios for experimental design
        ed_row = [r, fn_dat_new.split("_")[1].replace(".xlsx", ""), fn_sim_new.split("_")[1].replace(".xlsx", "")]
        df_ed.append(ed_row)

        ##  copy over

        #set paths
        fp_dat = os.path.join(dir_cur, fn_dat)
        fp_sim = os.path.join(dir_cur, fn_sim)
        #data
        fp_dat_new = os.path.join(dir_cp_mac, fn_dat_new)
        #sim
        fp_sim_new = os.path.join(dir_cp_mac, fn_sim_new)

        #copy paths
        shutil.copyfile(fp_dat, fp_dat_new)
        shutil.copyfile(fp_sim, fp_sim_new)


        print("run " + str(r) + " done.")

df_ed_out = pd.DataFrame(df_ed, columns = ["run_id", "data", "sim"])
#export design
fn_ed = "ieem_exp_design.csv"
df_ed_out.to_csv(os.path.join(root, nm_files_out, fn_ed), index = None, encoding = "UTF-8")

#===========================================================================================
# PART 2: TRANSFORM THE EXPERIMENTAL DESIGN INTO NEW FILES FOR RUNNING AND CREATE EXPERIMENTAL DESIGN TABLE
#===========================================================================================

import os, os.path
import numpy as np
import pandas as pd
import sys
import shutil

#function to build dictionaries
def build_dict(df_in):return dict([tuple(df_in.iloc[i]) for i in range(len(df_in))])

#get experimental design
fp_csv_exp_design = os.path.join(root, nm_files_out, fn_ed)
df_exp_design = pd.read_csv(fp_csv_exp_design)
df_exp_design = df_exp_design.sort_values(by = ["run_id"]).reset_index(drop = True)

#define paths for model
#file paths for files to read in/replace
fp_gms_data = os.path.join(root, "data.gms")
fp_gms_sim = os.path.join(root, "sim.gms")
fp_gms_repbaseyr = os.path.join(root, "repbaseyr.gms")
fp_gms_repenviro = os.path.join(root, "repenviro.gms")
fp_gms_reppov = os.path.join(root, "reppov.gms")

#file path for gams include files
name_app = "cri2016rand"
dir_uf = os.path.join(root, "user-files", name_app)
fp_inc_data = os.path.join(dir_uf, ("##APP##-data2.inc").replace("##APP##", name_app))
fp_inc_sim = os.path.join(dir_uf, ("##APP##-sim.inc").replace("##APP##", name_app))
fp_inc_sim2 = os.path.join(dir_uf, ("##APP##-sim2.inc").replace("##APP##", name_app))

#build dictionaries
dict_scen_to_dat = build_dict(df_exp_design[["run_id", "data"]])
dict_scen_to_sim = build_dict(df_exp_design[["run_id", "sim"]])
#all runs
#all_runs = list(df_exp_design["run_id"]) # this object already exists above

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
	f_tmp = open(dict_fps_in[fshort], "r") # this line opens the inc or gms files
	str_tmp = f_tmp.readlines()  #this line reads the lines inside those files
	f_tmp.close() #this line closes the connection
	#add to dictionary
	dict_strs_in[fshort] = str_tmp

#some test
#dict_strs_in["data"]
#dict_strs_in["inc_sim2"]

##  CLEAN FILES THAT NEED TO BE CLEANED

#output dictionary mapping file paths to clean to their output paths
all_fp_clean = [fp_gms_sim, fp_inc_sim] #this dictonary connects the sim.inc to the sim.gms file
#add to dictionary
dict_output_clean = {}

#define folders of where to read the sim.gms and sim.inc files and where to save these, this may not needed
dir_win = os.path.join(root,  "" ) #where to read them
dir_cur = os.path.join(root,  "user-files\\cri2016rand\\test\\" ) #where to save them

#loop over files to export linux versions
for fp in all_fp_clean:
    # fp = all_fp_clean[1] #for testing
	print("#"*30 + "\nStarting file " + os.path.basename(fp) + "...")

	fp_out = fp.replace(dir_win, dir_cur) #this line just updates the path from windows system to linux system, what is the difference between dir cur and dir win?

	#read from the windows side
	f_read = open(fp, "r")
	rl = f_read.readlines() #this opens the sim.gms file
	f_read.close()

	#export to the mac side, I think we may not need to write this, just putting the files in the dictionary should be enough
	f_write = open(fp_out, "w")
	f_write.writelines(rl)
	f_write.close()

	#set output key
	key_out = os.path.basename(fp)
	dict_output_clean.update({key_out: rl}) # this dictionary does have the sim files


#############################
#    LOOP OVER SCENARIOS    #
#############################
#the line below is an adjustment to the only windowns side system
dirw_win = root
# watch out for the double diagonalas after dirw_win +
# also note that this dictionay define this root for the excel files to exist
#C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-01-15\\\\user-files\\cri2016rand\\cri2016rand-data_d1.xlsx
#so basically remove the test directory and make to to #C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-01-15\\\\user-files\\cri2016rand\\
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
#I think we need to keep this function
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
dir_save = os.path.join(root, "save")
for scen in all_runs:
    #scen = 1 #for testing
	print(header)
	print("Starting data scenario: '" + str(scen) + "'...")

	#get data and sim
	scen_dat = "data_" + str(dict_scen_to_dat[scen]) #this is a dictionary
	scen_sim = "sim_" + str(dict_scen_to_sim[scen]) #this is a dictionary

	#update the file path save
	dir_save_scen = dir_save.replace("save", "save_" + str(scen))
	#make dirs
	if os.path.exists(dir_save_scen):
		shutil.rmtree(dir_save_scen)
	#create the new save directory
	os.makedirs(dir_save_scen, exist_ok = True) # this creates the directory, but the indententation is important


	##  EXPORT THE DATA INCLUDE FILE
	print("\Exporting dim.inc...")
	str_inc_dat_scen = dict_strs_in["inc_dat"].copy()
	#copy the dictionary
	dict_r_inc_dat = dict_scen_repl["inc_dat"].copy()
	#set the
	str_inc_dat_scen = do_repl(str_inc_dat_scen, dict_r_inc_dat, {"##DATASCEN##": scen_dat})
	#write to new file
	fp_new = fp_inc_data.replace(".inc", "_" + str(scen) + ".inc") #fp_inc_data is our target directory, this is the thing we need to change globally
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
	fp_new = fp_gms_data.replace(".gms", "_" + str(scen) + ".gms") # fp_gms_data is probably not correct and I need to chnage
	f_new = open(fp_new, "w")
	f_new.writelines(str_data_scen)
	f_new.close()
	#set windows path
#	fpw_new = fpw_gms_data.replace(".gms", "_" + str(scen) + ".gms")
#	dirw_save_scen = dir_save_scen.replace(dir_win, dirw_win).replace("/", "\\")

	#build windows command
#	comm = cmd_prlctrl.replace("##CMDAPP##", cmd_wingams) #we need to chnage this command
#	comm = comm.replace("##CMDSCRIPT##", fpw_new + " s=" + dirw_save_scen + "\\data --NonIMv2=1")
	#notify
#	print("Sending command:\n\t" + comm)
	#run gams
	#os.system(comm)


#continue from here tomorrow
	##  CALL THE GDXXRW FOR SIM

	print("\tCalling sim GDXXRW...")
	#use simulation (it's only one line) -- windows code to send via prlctl
	sim_gams_call = "$CALL GDXXRW user-files\\cri2016rand\\cri2016rand-##SIMSCEN##.xlsx index=layout!A1\n".replace("##SIMSCEN##", scen_sim)
	#set temporary file path out
	fn_tmp = "tmpsim_" + str(scen) + ".gms"
	fp_tmp = os.path.join(dir_win, fn_tmp)

	if os.path.exists(fp_tmp):
		os.remove(fp_tmp)
	fpw_tmp = dirw_win + "\\" + fn_tmp # this is going into the main model folder, shall it go there?
	#write to temporary file
	f_tmp = open(fp_tmp, "w")
	f_tmp.writelines(sim_gams_call)
	f_tmp.close()

	#build windows command
#	comm = cmd_prlctrl.replace("##CMDAPP##", cmd_wingams)
#	comm = comm.replace("##CMDSCRIPT##", fpw_tmp)
	#notify
#	print("Sending command:\n\t" + comm)
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
	f_new.writelines(str_inc_sim_scen) #this is writting everything on the test folder, whichis the user folder
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
	f_new.writelines(str_inc_sim2_scen) #this is writting everything on the test folder, which is the user folder
	f_new.close()


	##  BUILD AND EXPORT SIM.GMS LOCALLY. #take from here tomorrow

	print("\tBuilding sim.gms...")
	str_sim_scen = dict_output_clean["sim.gms"].copy()
	#copy the dictionary
	dict_r_sim = dict_scen_repl["sim"].copy()
	#update the string
	str_sim_scen = do_repl(str_sim_scen, dict_r_sim, {"##RUNID##": str(scen)})
	#set output file path
	fp_gms_sim_out = fp_gms_sim.replace(dir_win, dir_cur).replace(".gms", "_" + str(scen) + ".gms") # it is printing this in the test folder, not sure, this sould be the case
	#write
	f_new = open(fp_gms_sim_out, "w")
	f_new.writelines(str_sim_scen)
	f_new.close()

	print("Data scenario: '" + str(scen) + "' complete.")
	print(header)


#===========================================================================================
# PART 3: TRANSFORM THE EXPERIMENTAL DESIGN INTO NEW FILES FOR RUNNING AND CREATE EXPERIMENTAL DESIGN TABLE
#===========================================================================================
