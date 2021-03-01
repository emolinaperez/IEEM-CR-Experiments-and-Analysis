import os, os.path
import shutil


##  DIRECTORIES

#get current directory
dir_cur = os.path.dirname(os.path.realpath(__file__))
#set app name
name_app = "cri2016rand"
#set the working directory
dir_win = "/Volumes/[C] syme-j-PVM.hidden/Users/jsyme/Documents/Projects/SWCHE093-1000/IEEM-en-GAMS-with-EXCAP-2021-01-15"

#check for gdx files
files_copy = [x for x in os.listdir(dir_win) if (".gdx" in x)]
files_copy = [x for x in files_copy if (x[-4:] == ".gdx")]
#add experimental design
files_copy = files_copy + ["ieem_exp_design.csv"]

for fg in files_copy:
	print("copying: " + fg)
	shutil.copyfile(os.path.join(dir_win, fg), os.path.join(dir_cur, fg))


##  GET SAVE DIRECTORIES

dirs_copy = [x for x in os.listdir(dir_win) if ("save" in x) and ("." not in x)]
dirs_copy = dirs_copy + ["user-files"]
#copy over
for dc in dirs_copy:
	if dc in os.listdir(dir_cur):
		shutil.rmtree(os.path.join(dir_cur, dc))
	#then copy over
	dp_src = os.path.join(dir_win, dc)
	dp_tar = os.path.join(dir_cur, dc)
	#notify
	print("copying directory '" + dp_src + "' to '" + dp_tar + "'")
	#copy over
	comm = ("cp -r \"" + dp_src + "\" \"" + dp_tar + "\"")
	print(comm)
	os.system(comm)
	
#set working directory up
dir_working = os.path.dirname(dir_cur)
os.chdir(dir_working)

dirn_cur = os.path.basename(dir_cur)
#file name of tarball
fn_tar = "ieem_up.tar.gz"
#check for existsence
if os.path.exists(os.path.join(dir_working, fn_tar)):
	os.remove(os.path.join(dir_working, fn_tar))
#tar gz up
comm = "COPYFILE_DISABLE=1 tar -cvzf " + fn_tar + " " + dirn_cur

print("creating tar upload...")
os.system(comm)
