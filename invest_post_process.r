#post_process investment shock results

#in pc
  root<-"C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\"
  ieem.folder<-"IEEM-en-GAMS-with-EXCAP-2021-01-25\\"
  in.folder<-"calib_results\\"
  out.folder<-"investment_result_all\\"
  nm_files_out <- "user-files\\cri2016rand\\"
  var.names.file.dir<-"IEEM-CR-Experiments-and-Analysis\\Vars_Code_v2.csv"
  census.data.file.dir<-"IEEM-CR-Experiments-and-Analysis\\econ_indicators-annual_2010-2020_new.csv"
  va.data.file.dir<-"IEEM-CR-Experiments-and-Analysis\\value_added-annual_2010-2020_new.csv"
  ed.name<-"exp_design_2021_04_20_invest.csv"

#in server
 root<-"D:\\1. Projects\\30. Costa Rica COVID19\\"
 ieem.folder<-"IEEM-en-GAMS-with-EXCAP-2021-01-25\\"
 in.folder<-"calib_results\\"
 out.folder<-"investment_result_all\\"
 nm_files_out <- "user-files\\cri2016rand\\"
 var.names.file.dir<-"IEEM-CR-Experiments-and-Analysis\\Vars_Code_v2.csv"
 census.data.file.dir<-"IEEM-CR-Experiments-and-Analysis\\econ_indicators-annual_2010-2020_new.csv"
 va.data.file.dir<-"IEEM-CR-Experiments-and-Analysis\\value_added-annual_2010-2020_new.csv"
 ed.name<-"exp_design_2021_04_20_invest.csv"



 process.meso<-function(filename.meso,
                         var.names.file
                         ) {

#read file
#  filename.meso<-  filenames.meso [1]
  meso<- read.csv(paste0(root,ieem.folder,in.folder,"meso//",filename.meso) )

vars<-c(
        "Employment_gr",
        "exports_gr",
        "houselholds.cosumption_gr",
        "imports_gr",
        "value.added_gr",
        "Employment_rv",
        "exports_rv",
        "houselholds.cosumption_rv",
        "imports_rv",
        "value.added_rv"
       )

#now create variable to compare against base
  meso.b<-subset(meso,Scenario=='base')
  meso.b$index<-paste0(meso.b$Sector,'_',meso.b$Year)
  meso.b<-meso.b[,c('index',vars)]
  colnames(meso.b)<-c('index',paste0(vars,"-B"))

#merge with meso
  meso$index<-paste0(meso$Sector,'_',meso$Year)
  meso<-merge(meso,meso.b,by="index",all.x=TRUE)

#now estimate difference with respect to base
 for (i in 1:length(vars))
 {
  meso[,paste0(vars[i],"-B")]<-meso[,vars[i]]-meso[,paste0(vars[i],"-B")]
 }

# Include translation,
  snames<-read.csv(var.names.file)
##check all sectors are in code book
  subset(unique(meso$Sector),!(unique(meso$Sector)%in%unique(snames$Sector)))

#merge
 dim(meso)
 meso<-merge(meso,snames,by="Sector")
 dim(meso)
 meso$index<-NULL

#id
 meso$Run.id<-gsub("calib_report","",filename.meso)
 meso$Run.id<-as.numeric(gsub(".csv","",meso$Run.id))
 meso

}

#macro function
process.macro<-function(filename.macro,
                        var.names.file
                        ) {

#read file
#  filename.macro<-  filenames.macro [1]
 macro<- read.csv(paste0(root,ieem.folder,in.folder,"macro//",filename.macro) )
#
#marco report
mvars<-c("Unemployment","Absorption","DeprCap","EmiVal","Exports","FixInv","GDPFC","GDPMP",
        "GenuineSavProx","GNDI","GNI","GNSAV","GovCon","GovFixInv","Imports",
        "NetIndTax","PrvCon","PrvFixInv","StockChange")

#
macro.b<-subset(macro,Scenario=='base')
colnames(macro.b)<-c('Year',paste0(mvars,"-B"))

#merge
dim(macro)
dim(macro.b)
macro<-merge(macro,macro.b,by="Year",all.x=TRUE)
dim(macro)

for (i in 1:length(mvars))
{
macro[,paste0(mvars[i],"-B")]<-macro[,mvars[i]]-macro[,paste0(mvars[i],"-B")]
}

#id
macro$Run.id<-gsub("calib_report","",filename.macro)
macro$Run.id<-as.numeric(gsub(".csv","",macro$Run.id))
macro

}



# read list of files
   filenames.meso <- list.files(paste0(root,ieem.folder,in.folder,"meso//"), pattern="*.csv", full.names=FALSE)
   filenames.macro <- list.files(paste0(root,ieem.folder,in.folder,"macro//"), pattern="*.csv", full.names=FALSE)

 files<-data.frame(meso=filenames.meso,
                   macro=filenames.meso)

#execute funtion
#this is the function
  var.names.file<-paste0(root,var.names.file.dir)

#process meso report
   meso_results<-apply(files,1,function(x){process.meso(x['meso'],var.names.file)})
   meso_results<-do.call('rbind',meso_results)
   ExpDesign<-read.csv(paste(root,ieem.folder,nm_files_out,ed.name,sep=""))
   meso_results<-merge(meso_results,ExpDesign[,c("covid.shock","investment.shock","calib.run","Run.id")],by="Run.id",all.x=TRUE)

#unique identifiers
  meso_results$id<-with(meso_results,paste(calib.run,covid.shock,investment.shock,Scenario,sep="_"))
  Ameso<-unique(meso_results[,c("id","calib.run","covid.shock","investment.shock","Scenario")])
  Ameso[,"COVID Recovery"]<-Ameso$covid.shock
  Ameso[,"COVID Recovery"]<-ifelse(Ameso$Scenario=='base',"n/a",Ameso[,"COVID Recovery"])
  Ameso$Include<-1
  Ameso$Include<-ifelse(Ameso$Scenario=='base' & Ameso$investment.shock!='scenario 0',0,Ameso$Include)
#this piece is only for the tornado plot
#####

low.shock<-paste0("s",c(2:31))
mid.shock<-paste0("s",c(32:61))
high.shock<-paste0("s",c(62:90))

Ameso[,"Decarb Investment"]<-ifelse(Ameso$investment.shock%in%low.shock,'low shock',
                                          ifelse(Ameso$investment.shock%in%mid.shock,'mid shock',
                                                  ifelse(Ameso$investment.shock%in%high.shock,'high shock','no invest shock')))


######
#this is the original piece
#  Ameso[,"Decarb Investment"]<-ifelse(Ameso$investment.shock=='scenario 0','none',
#                                          ifelse(Ameso$investment.shock=='scenario 1','5-years of investment',
#                                                  ifelse(Ameso$investment.shock=='scenario 2','10-years of investment','15-years of investment')))


  colnames(Ameso)<-c("id","Calibration_id","Recovery_code","Investment_id","End_tag","COVID Recovery","Include","Decarb Investment")

#write results
 #remove uselss runs in both data sets
  meso_results<-subset(meso_results,!(investment.shock%in%c("s31","s61")))
  Ameso<-subset(Ameso,!(Investment_id%in%c("s31","s61")))

#add sector hit
  sh<-read.csv("D:\\1. Projects\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-01-25\\user-files\\cri2016rand\\invest_sector_table.csv")
  Ameso<-merge(Ameso,sh,by="Investment_id")

  write.csv(meso_results, paste0(root,ieem.folder,out.folder,"meso_report_2021_04_20.csv"), row.names=FALSE)
  write.csv(Ameso, paste0(root,ieem.folder,out.folder,"attributes_meso_report_2021_04_20.csv"), row.names=FALSE)


#append so is the same as before





#append base scenario
#  meso_results$covid.shock<-ifelse(meso_results$Scenario=="base","None",meso_results$covid.shock)
#  meso_results$investment.shock<-ifelse(meso_results$Scenario=="base","None",meso_results$investment.shock)



#now process macro
   macro_results<-apply(files,1,function(x){process.macro(x['macro'],var.names.file)})
   macro_results<-do.call('rbind',macro_results)

#append so is the same as before
  macro_results$id<-paste0(macro_results$Run.id,"-",macro_results$Scenario)
  ExpDesign<-read.csv(paste(root,ieem.folder,nm_files_out,ed.name,sep=""))
  macro_results<-merge(macro_results,ExpDesign[,c("covid.shock","investment.shock","calib.run","Run.id")],by="Run.id",all.x=TRUE)
#append base scenario
  macro_results$covid.shock<-ifelse(macro_results$Scenario=="base","None",macro_results$covid.shock)
#  macro_results$investment.shock<-ifelse(macro_results$Scenario=="base","None",macro_results$investment.shock)

#write results
  write.csv(macro_results, paste0(root,ieem.folder,out.folder,"macro_report_2021_04_09.csv"), row.names=FALSE)
