#================================================================================
#This scripts controls ieem simulations and calls all supporting functions
#================================================================================
#Set parameters for the model
#root directory for everything
#in pc
#  root.all<-"C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\"
#  gams.postprocess.version<-"C:\\GAMS\\win64\\28.2\\"
#  py.script.name<- "IEEM-CR-Experiments-and-Analysis\\Windows_integration_one_single_run.py"
#in server
  root.all<-"D:\\1. Projects\\30. Costa Rica COVID19\\"
  gams.postprocess.version<-"C:\\GAMS\\win64\\27.3\\"
  py.script.name<- "IEEM-CR-Experiments-and-Analysis\\Windows_integration_one_single_run_server.py"
# General parameters
  ieem.folder<-"IEEM-en-GAMS-with-EXCAP-2021-01-25\\"
  py.version<- "C:\\ProgramData\\Anaconda3\\python.exe"
  post.process.script<-"IEEM-CR-Experiments-and-Analysis\\post_process_ieem.r"
  py.script<-paste0('"',paste0(root.all,py.script.name),'"')
  nm_files_out <- "user-files\\cri2016rand\\"
  tmp_dir <- "ieem_results\\"
  name_app <- "cri2016rand"
  out.folder<-"calib_results\\"
  var.names.file.dir<-"IEEM-CR-Experiments-and-Analysis\\Vars_Code_v2.csv"
  census.data.file.dir<-"IEEM-CR-Experiments-and-Analysis\\econ_indicators-annual_2010-2020_new.csv"
  invest.name<-"invest_shocks_2021_04_20.csv"
  #ed.name<-"exp_design_test.csv"
  ed.name<-"exp_design_2021_04_20_invest.csv"

#load experimental design
  ExpDesign<-read.csv(paste(root.all,ieem.folder,nm_files_out,ed.name,sep=""))
  ScenTable<-read.csv(paste(root.all,ieem.folder,nm_files_out,invest.name,sep=""))
#source post processing script
  source(paste0(root.all,post.process.script))

for (i in 268:nrow(ExpDesign)){
 #i<-9
 run_id<-i
#create the data and sim excel files
 options(java.parameters = "-Xmx8000m")
 library("xlsx")
 jgc <- function()
            {
             gc()
             .jcall("java/lang/System", method = "gc")
            }

# Create sim file
 file.sim<-"invest_cri2016rand-sim"
 SimFile<-loadWorkbook(paste0(root.all,ieem.folder,nm_files_out,file.sim,".xlsx"))
 sheet<-getSheets(SimFile)$shklprd
 cb1 <- CellBlock(sheet, 2, 2, 39, 1, create = FALSE)
 cb2 <- CellBlock(sheet, 2, 6, 39, 1, create = FALSE)
 newlaborshocks<-as.numeric(ExpDesign[run_id,1:39])
#
 CB.setColData(cb1, newlaborshocks, 1)
 CB.setColData(cb2, newlaborshocks, 1)

#next read the invest scenarios table and select the corresponding scenario
 invest_scenario.table<-subset(ScenTable,investment.shock==ExpDesign[run_id,"investment.shock"])
 invest_scenario.table<-as.matrix(invest_scenario.table[,paste0("X",c(2016:2025))])
 colnames(invest_scenario.table)<-NULL
 rownames(invest_scenario.table)<-NULL
 InvestSheet<-getSheets(SimFile)$dqksim
 cb3 <- CellBlock(InvestSheet, 4, 4, 29, 10, create = FALSE)
 CB.setMatrixData(cb3,invest_scenario.table, 1, 1)

#next change the values for the investment shock
 oneyr<-c(0,0,0,0,1,0,0,0,0,0,0,0,0,0,0)
 threeyr<-c(0,0,0,0,1,0.666666667,0.333333333,0,0,0,0,0,0,0,0)
 fiveyr<-c(0,0,0,0,1,0.8,0.6,0.4,0.2,0,0,0,0,0,0)

 shocks<-list(c(0,0,0,0,1,0,0,0,0,0,0,0,0,0,0),c(0,0,0,0,1,0.666666667,0.333333333,0,0,0,0,0,0,0,0),c(0,0,0,0,1,0.8,0.6,0.4,0.2,0,0,0,0,0,0))
 names(shocks)<-c("1-year","3-year","5-year")

 ShockSheet<-getSheets(SimFile)$rec135yr
 cb4 <- CellBlock(ShockSheet, 11, 2, 1, 15, create = FALSE)
 shockyr<-as.numeric(shocks[[ExpDesign[run_id,"covid.shock"]]])
 CB.setMatrixData(cb4,matrix(shockyr,1,15), 1, 1)

#write new sim file
 file.sim<-gsub("invest_","",file.sim)
 saveWorkbook(SimFile,paste0(root.all,ieem.folder,nm_files_out,file.sim,"_s",run_id,".xlsx"))

#Create data file
 file.data<-"invest_cri2016rand-data"
 DataFile<-loadWorkbook(paste0(root.all,ieem.folder,nm_files_out,file.data,".xlsx"))
 sheet1<-getSheets(DataFile)$unemp
 cb1 <- CellBlock(sheet1, 3, 3, 3, 1, create = FALSE)
 newunemp<-as.numeric(ExpDesign[run_id,79:81])
 CB.setColData(cb1,newunemp , 1)
 sheet2<-getSheets(DataFile)$excap
 cb2 <- CellBlock(sheet2, 3, 4, 39, 1, create = FALSE)
 newexcaps<-as.numeric(ExpDesign[run_id,40:78])
 CB.setColData(cb2,  newexcaps, 1)
 file.data<-gsub("invest_","",file.data)
 saveWorkbook(DataFile, paste0(root.all,ieem.folder,nm_files_out,file.data,"_d",run_id,".xlsx"))

#execute java garbage collection
  library("rJava")
  jgc()

#Put together command for windows shell
  command <- noquote(paste(py.version,py.script,run_id,sep = " "))

#Execute command
  system(command
                ,intern=TRUE
                ,ignore.stdout = FALSE
                ,ignore.stderr = FALSE
                ,wait = TRUE
                ,show.output.on.console = TRUE
                ,minimized = FALSE
                ,invisible = FALSE
          )


#Post-process results
#Set parameters
 dir.data<-paste0(root.all,ieem.folder,tmp_dir)
 dir.out<-paste0(root.all,ieem.folder,out.folder)
 gams_version<-gams.postprocess.version
 var.names.file<-paste0(root.all,var.names.file.dir)
 census.data.file<-paste0(root.all,census.data.file.dir)

#Execute script
 post_process_ieem(dir.data,dir.out,run_id,gams_version,var.names.file,census.data.file)

#Erase all not needed files
#remove gdx files
  file.namesp1<-c("rank_in_run","rank_out_run","repmeso2-cri2016rand_run","repmacro2-cri2016rand_run")
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
              paste0(root.all,ieem.folder,file.namesp4),
              paste0(paste0(root.all,ieem.folder,nm_files_out),c(file.namesp5,file.namesp6))
             )
           )
}
