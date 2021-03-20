
import os, os.path;
import shutil;
import pandas as pd;



##  SET THE NAME OF THE RUNS (CALIBRATION) PACKAGE HERE
nm_files_in = "Calib Runs 2021-02-26"
## FULL PATH OF RUN PACKAGE
root = "C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-01-15\\user-files\\cri2016rand\\"
dir_files_in = os.path.join(root, nm_files_in)

#all excel files
all_runs = [int(x.replace("r", "")) for x in os.listdir(dir_files_in) if ("." not in x) and (x[0] == "r")]
all_runs.sort()


##  SET TARGET DIRECTORIES HERE--I USED BOTH WINDOWS AND MAC DIRECTORIES, BUT YOU SHOULD BE ABLE TO STICK WITH dir_cp_mac ASSUMING THIS FILE IS AT THE SAME LEVEL OF "IEEM-en-GAMS-with-EXCAP-2021-01-15"

#set directories to copy into
root2 = "C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-01-15\\user-files\\cri2016rand\\cri2016rand_test\\"
dir_cp_mac = os.path.join(root2)
#dir_cp_win = "/Volumes/[C] syme-j-PVM.hidden/Users/jsyme/Documents/Projects/SWCHE093-1000/IEEM-en-GAMS-with-EXCAP-2021-01-15/user-files/cri2016rand"

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
        #fp_dat_new_win = os.path.join(dir_cp_win, fn_dat_new)
        #sim
        fp_sim_new = os.path.join(dir_cp_mac, fn_sim_new)
        #fp_sim_new_win = os.path.join(dir_cp_win, fn_sim_new)

        #copy paths
        shutil.copyfile(fp_dat, fp_dat_new)
        #shutil.copyfile(fp_dat, fp_dat_new_win)
        shutil.copyfile(fp_sim, fp_sim_new)
        #shutil.copyfile(fp_sim, fp_sim_new_win)

        print("run " + str(r) + " done.")

df_ed_out = pd.DataFrame(df_ed, columns = ["run_id", "data", "sim"])

#export design
root3 = "C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-01-15\\user-files\\cri2016rand\\cri2016rand_test\\"
dir_ed_out = os.path.dirname(root3)
#dir_ed_out_win = os.path.dirname(os.path.dirname(dir_cp_win))
fn_ed = "ieem_exp_design.csv"
df_ed_out.to_csv(os.path.join(dir_ed_out, fn_ed), index = None, encoding = "UTF-8")
