#set parameters for the model
#This scripts controls ieem simulations and calls all supporting functions
 py.version<- "C:\\ProgramData\\Anaconda3\\python.exe"
 py.script<- noquote('"C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-CR-Experiments-and-Analysis\\Windows_integration_one_single_run.py"')
# root <- noquote('"C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-03-28\\"')
 nm_files_out <- "user-files\\cri2016rand\\"
 tmp_dir <- "ieem_results"
 name_app <- "cri2016rand"


#load experimental design
# ed.name<-"exp_design_2021_03_27.csv"
 ed.name<-"exp_design_test.csv"
 root<-"C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-03-28\\"
 ExpDesign<-read.csv(paste(root,nm_files_out,ed.name,sep=""))

for (i in 1:2){
 run_id<-i
#create the data and sim excel files
 options(java.parameters = "-Xmx8000m")

 library("xlsx")
 jgc <- function()
{
  gc()
  .jcall("java/lang/System", method = "gc")
}

# sim file first
 file.sim<-"cri2016rand-sim"
 SimFile<-loadWorkbook(paste0(root,nm_files_out,file.sim,".xlsx"))
 sheet<-getSheets(SimFile)$shklprd
 cb1 <- CellBlock(sheet, 2, 2, 39, 1, create = FALSE)
 cb2 <- CellBlock(sheet, 2, 6, 39, 1, create = FALSE)
 newlaborshocks<-as.numeric(ExpDesign[run_id,1:39])
#
 CB.setColData(cb1, newlaborshocks, 1)
 CB.setColData(cb2, newlaborshocks, 1)
 saveWorkbook(SimFile,paste0(root,nm_files_out,file.sim,"_s",run_id,".xlsx"))

#data file second
 file.data<-"cri2016rand-data"
 DataFile<-loadWorkbook(paste0(root,nm_files_out,file.data,".xlsx"))
 sheet2<-getSheets(DataFile)$excap
 cb2 <- CellBlock(sheet2, 3, 4, 39, 1, create = FALSE)
 newexcaps<-as.numeric(ExpDesign[run_id,40:78])
 CB.setColData(cb2,  newexcaps, 1)
 saveWorkbook(DataFile, paste0(root,nm_files_out,file.data,"_d",run_id,".xlsx"))

#java garbage collection
 library("rJava")
 jgc()

#command <- noquote(paste(py.version,py.script, sep = " "))
command <- noquote(paste(py.version,py.script,run_id,sep = " "))

#command <- noquote(paste(py.version,py.script,root,nm_files_out,tmp_dir,name_app, sep = " "))

system(command
          ,intern=TRUE
          ,ignore.stdout = FALSE
          ,ignore.stderr = FALSE
          ,wait = TRUE
          ,show.output.on.console = TRUE
          ,minimized = FALSE
          ,invisible = FALSE
          )


#post-process results
 dir.data<-"C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-03-28\\ieem_results\\"
 dir.out<-"C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-03-28\\calib_results\\"
 gams_version<-"C:\\GAMS\\win64\\28.2\\"
 var.names.file<-"C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\Output\\Vars_Code_v2.csv"
 census.data.file<-"C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\Output\\econ_indicators-annual_2010-2020_new.csv"

 source("C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-CR-Experiments-and-Analysis\\post_process_ieem.r")
 post_process_ieem(dir.data,dir.out,run_id,gams_version,var.names.file,census.data.file)

#erase all not needed file
#remove gdx files
  file.namesp1<-c("rank_in_run","rank_out_run","repmeso2-cri2016rand_run","repmacro2-cri2016rand_run","cri2016rand-sim_run")
  file.namesp1<-paste0(file.namesp1,"-",run_id,".gdx")
  file.namesp2<-paste0("cri2016rand-sim_s",run_id,".gdx")
  file.namesp3<-paste0("cri2016rand-data_d",run_id,".gdx")
#remove files in root
  file.namesp4 <- c("tmpsim_","sim_","data_")
  file.namesp4 <- paste0(file.namesp4,run_id,".gms")

#remove files in user files directory
  file.namesp5 <-c("cri2016rand-sim_s","cri2016rand-data_d")
  file.namesp5 <- paste0(file.namesp5,run_id,".xlsx")
  file.namesp6 <-c("cri2016rand-sim2_","cri2016rand-sim_","cri2016rand-data2_")
  file.namesp6 <- paste0(file.namesp6,run_id,".inc")

#erase all files
file.remove(
            c(
              paste0(dir.data,c(file.namesp1,file.namesp2,file.namesp3)),
              paste0(root,file.namesp4),
              paste0(paste0(root,nm_files_out),c(file.namesp5,file.namesp6))
             )
           )
}
