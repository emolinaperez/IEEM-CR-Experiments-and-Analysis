#post_process calib results

#in pc
#   root<-"C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\"
#   ieem.folder<-"IEEM-en-GAMS-with-EXCAP-2021-01-25\\"
#   in.folder<-"calib_results\\"
#   out.folder<-"calib_result_all\\"
#   var.names.file.dir<-"IEEM-CR-Experiments-and-Analysis\\Vars_Code_v2.csv"
#   census.data.file.dir<-"IEEM-CR-Experiments-and-Analysis\\econ_indicators-annual_2010-2020_new.csv"
#   va.data.file.dir<-"IEEM-CR-Experiments-and-Analysis\\value_added-annual_2010-2020_new.csv"

#in server
 root<-"D:\\1. Projects\\30. Costa Rica COVID19\\"
 ieem.folder<-"IEEM-en-GAMS-with-EXCAP-2021-01-25\\"
  in.folder<-"calib_results\\"
 #in.folder<-"calib_results_2021_04_06\\"
 #in.folder<-"calib_results_2021_04_01\\"
 out.folder<-"calib_result_all\\"
 var.names.file.dir<-"IEEM-CR-Experiments-and-Analysis\\Vars_Code_v2.csv"
 census.data.file.dir<-"IEEM-CR-Experiments-and-Analysis\\econ_indicators-annual_2010-2020_new.csv"
 va.data.file.dir<-"IEEM-CR-Experiments-and-Analysis\\value_added-annual_2010-2020_new.csv"




 process.calib<-function(filename.meso,
                         filename.macro,
                         var.names.file,
                         census.data.file,
                         va.data.file,
                         tol,
                         tolva
                         ) {

#read file
#  filename.meso<-  filenames.meso [1]
  meso<- read.csv(paste0(root,ieem.folder,in.folder,"meso//",filename.meso) )

# Include translation,
  snames<-read.csv(var.names.file)
##check all sectors are in code book
  subset(unique(meso$Sector),!(unique(meso$Sector)%in%unique(snames$Sector)))

#merge
 dim(meso)
 meso<-merge(meso,snames,by="Sector")
 dim(meso)

#now process the actual data
#aggregate employment per sector Calib
 meso<-aggregate(meso[,c("Employment_rv","value.added_rv")],list(
                                             Scenario=meso$Scenario,
                                             Year=meso$Year,
                                             Sector_Calib=meso$Sector_Calib
                                             ),sum)
#meso$Employment_rv<-meso$x
#meso$x<-NULL

#now create variable to compare against base
  meso.b<-subset(meso,Scenario=='base')
  meso.b$index<-paste0(meso.b$Sector_Calib,'_',meso.b$Year)
  meso.b<-meso.b[,c('index','Employment_rv',"value.added_rv")]
  colnames(meso.b)<-c('index','Employment_rv-B',"value.added_rv-B")
#create index in meso
  meso$index<-paste0(meso$Sector_Calib,'_',meso$Year)
  dim(meso)
  dim(meso.b)
  meso<-merge(meso,meso.b,by="index",all.x=TRUE)
  dim(meso)
  meso$index<-NULL

#just focus in 2020
  meso<-subset(meso,Year==2020)
#difference in employment
  meso$Employment_rv_Diff<-meso[,'Employment_rv']-meso[,'Employment_rv-B']
  meso$Employment_rv_PctDiff<-(meso[,'Employment_rv']-meso[,'Employment_rv-B'])/meso[,'Employment_rv-B']
#differente in value added
  meso$value.added_rv_Diff<-meso[,'value.added_rv']-meso[,'value.added_rv-B']
  meso$value.added_rv_PctDiff<-(meso[,'value.added_rv']-meso[,'value.added_rv-B'])/meso[,'value.added_rv-B']

#i want to merge GDP decline
#  filename.macro <-  filenames.macro [1]
  macro<- read.csv(paste0(root,ieem.folder,in.folder,"macro//",filename.macro) )
  macro<-macro[,c('Scenario','Year','GDPFC')]
  macro.b<-subset(macro,Scenario=='base')
  macro.b<-macro.b[,c('Year','GDPFC')]
  colnames(macro.b)<-c('Year','GDPFC-B')
  dim(macro)
  dim(macro.b)
  macro<-merge(macro,macro.b,by="Year",all.x=TRUE)
  dim(macro)

#just focus in 2020
    macro<-subset(macro,Year==2020)
    macro$GDPFC_Diff<-macro[,'GDPFC']-macro[,'GDPFC-B']
    macro$GDPFC_PctDiff<-(macro[,'GDPFC']-macro[,'GDPFC-B'])/macro[,'GDPFC-B']

#merge
  dim(meso)
  dim(macro)
  meso<-merge(meso,macro[,c('Scenario','GDPFC_Diff','GDPFC_PctDiff')],by='Scenario',all.x=TRUE)
  dim(meso)


#merge this report with employment decline in census
  census<-read.csv(paste(census.data.file,sep=""))
  census$Employment_census<-census[,'Employment..people.']/1000
  census<-subset(census,Year%in%c(2019,2020))
  census<-aggregate(census[,"Employment_census"],list(Sector_Calib=census$sector.en,
                                                      Year=census$Year
                                                        ),sum)
census$Employment_census<-census$x
census$x<-NULL

#add total- home employees here
 census.dummy<-data.frame(Sector_Calib='total minus households',
                          Year=c(2019,2020),
                          Employment_census=c(
                                              subset(census,Sector_Calib=='total' & Year==2019)$Employment_census-subset(census,Sector_Calib=='Home employees' & Year==2019)$Employment_census,
                                              subset(census,Sector_Calib=='total' & Year==2020)$Employment_census-subset(census,Sector_Calib=='Home employees' & Year==2020)$Employment_census
                                              )
                         )
#rbind
 census<-rbind(census,census.dummy)

#create actual value reference
 census.ref<-reshape2::dcast(census,Sector_Calib ~ Year, value.var = "Employment_census" )
 colnames(census.ref)<-c("Sector_Calib","Employment_2019","Employment_2020")

#create comparison base
census.b<-subset(census,Year==2019)
census.b$Year<-NULL
colnames(census.b)<-c('Sector_Calib','Employment_census2019')
census<-subset(census,Year==2020)
census$Year<-NULL

#merge both
 dim(census)
 dim(census.b)
 census<-merge(census,census.b,by='Sector_Calib')
 dim(census)

#calculate differences
 census$CensusEmployment_rv_Diff<-census$Employment_census-census$Employment_census2019
 census$CensusEmployment_rv_PctDiff<-(census$Employment_census-census$Employment_census2019)/census$Employment_census2019

#merge all
 dim(meso)
 dim(census)
 meso<-merge(meso,census[,c('Sector_Calib','CensusEmployment_rv_Diff','CensusEmployment_rv_PctDiff')],by='Sector_Calib',all.x=TRUE)
 dim(meso)

#do the same but for value added
  census.va<-read.csv(va.data.file)
  census.va$ValueAdded_census<-census.va[,'Billions.of.colones_deflated']

census.va<-subset(census.va,Year%in%c(2019,2020))
census.va<-aggregate(census.va[,"ValueAdded_census"],list(Sector_Calib=census.va$Sector_Calib,
                                                      Year=census.va$Year
                                                        ),sum)
census.va$ValueAdded_census<-census.va$x
census.va$x<-NULL

#make home employees correction
#I assume home employees falls inside "Commerce, repairs,professional and administrative activities"
 he.ratio.2019<-subset(meso,Scenario=="combi-rec5yr" & Sector_Calib=="Home employees")[,"value.added_rv-B"]/
                subset(meso,Scenario=="combi-rec5yr" & Sector_Calib=="Commerce, repairs,professional and administrative activities")[,"value.added_rv-B"]

#
 he.ratio.2020<-subset(meso,Scenario=="combi-rec5yr" & Sector_Calib=="Home employees")[,"value.added_rv"]/
                subset(meso,Scenario=="combi-rec5yr" & Sector_Calib=="Commerce, repairs,professional and administrative activities")[,"value.added_rv"]

#correct census
#for 2019
 census.va$ValueAdded_census[census.va$Sector_Calib=='Commerce, repairs,professional and administrative activities' &
                             census.va$Year==2019]<-(1-he.ratio.2019)*census.va$ValueAdded_census[census.va$Sector_Calib=='Commerce, repairs,professional and administrative activities' & census.va$Year==2019]

#for 2020
 census.va$ValueAdded_census[census.va$Sector_Calib=='Commerce, repairs,professional and administrative activities' &
                            census.va$Year==2020]<-(1-he.ratio.2019)*census.va$ValueAdded_census[census.va$Sector_Calib=='Commerce, repairs,professional and administrative activities' & census.va$Year==2020]

#
 he.va<-data.frame(Sector_Calib=c("Home employees","Home employees"),
                   Year=c(2019,2020),
                   ValueAdded_census=c(
                                        (he.ratio.2019)*census.va$ValueAdded_census[census.va$Sector_Calib=='Commerce, repairs,professional and administrative activities' & census.va$Year==2019],
                                        (he.ratio.2019)*census.va$ValueAdded_census[census.va$Sector_Calib=='Commerce, repairs,professional and administrative activities' & census.va$Year==2020]
                                       )
                    )

#rbind
 census.va<-rbind(census.va,he.va)

#add total- home employees here
 census.va.dummy<-data.frame(Sector_Calib='total minus households',
                          Year=c(2019,2020),
                          ValueAdded_census=c(
                                              subset(census.va,Sector_Calib=='total' & Year==2019)$ValueAdded_census-subset(census.va,Sector_Calib=='Home employees' & Year==2019)$ValueAdded_census,
                                              subset(census.va,Sector_Calib=='total' & Year==2020)$ValueAdded_census-subset(census.va,Sector_Calib=='Home employees' & Year==2020)$ValueAdded_census
                                              )
                         )
#rbind
 census.va<-rbind(census.va,census.va.dummy)

#create actual value reference
 census.va.ref<-reshape2::dcast(census.va,Sector_Calib ~ Year, value.var = "ValueAdded_census" )
 colnames(census.va.ref)<-c("Sector_Calib","VA_2019","VA_2020")



#continue with the process
census.va.b<-subset(census.va,Year==2019)
census.va.b$Year<-NULL
colnames(census.va.b)<-c('Sector_Calib','ValueAdded_census2019')
census.va<-subset(census.va,Year==2020)
census.va$Year<-NULL

#merge both
 dim(census.va)
 dim(census.va.b)
 census.va<-merge(census.va,census.va.b,by='Sector_Calib')
 dim(census.va)

#calculate differences
 census.va$CensusValueAdded_rv_Diff<-census.va$ValueAdded_census-census.va$ValueAdded_census2019
 census.va$CensusValueAdded_rv_PctDiff<-(census.va$ValueAdded_census-census.va$ValueAdded_census2019)/census.va$ValueAdded_census2019

#merge all
  dim(meso)
  dim(census.va)
  meso<-merge(meso,census.va[,c('Sector_Calib','CensusValueAdded_rv_Diff','CensusValueAdded_rv_PctDiff')],by='Sector_Calib',all.x=TRUE)
  dim(meso)

#process for calibration comparison
 meso<-subset(meso,Scenario=='combi-rec5yr')[,c("Sector_Calib","Employment_rv_PctDiff","CensusEmployment_rv_PctDiff","value.added_rv_PctDiff","CensusValueAdded_rv_PctDiff")]
#set tolerance for employment
 meso$Tol_min<-(1-tol)*meso$CensusEmployment_rv_PctDiff
 meso$Tol_max<-(1+tol)*meso$CensusEmployment_rv_PctDiff
#set tolerance for added value
 meso$Tolva_min<-(1-tolva)*meso$CensusValueAdded_rv_PctDiff
 meso$Tolva_max<-(1+tolva)*meso$CensusValueAdded_rv_PctDiff

#identify whether or not the simulation meets the target
#employment
 meso$HitTarget<-ifelse(meso$Employment_rv_PctDiff<=meso$Tol_min & meso$Employment_rv_PctDiff>=meso$Tol_max,1,0 )
 meso$Totalhits<-sum(meso$HitTarget)
#value added
 meso$HitTargetVa<-ifelse(meso$value.added_rv_PctDiff<=meso$Tolva_min & meso$value.added_rv_PctDiff>=meso$Tolva_max,1,0 )
 meso$Totalhitsva<-sum(meso$HitTargetVa)

#identify hits for both sectors
  meso$HitTargetBoth<-ifelse(meso$HitTargetVa+meso$HitTarget>=2,1,0)
  meso$TotalhitsBoth<-sum(meso$HitTargetBoth)

#total this accross both variables
  meso$TotalIndhits<-sum(meso$HitTargetVa)+sum(meso$HitTarget)

#id
 meso$Run.id<-gsub("calib_report","",filename.meso)
 meso$Run.id<-as.numeric(gsub(".csv","",meso$Run.id))
 meso

}

# read list of files
   filenames.meso <- list.files(paste0(root,ieem.folder,in.folder,"meso//"), pattern="*.csv", full.names=FALSE)
   filenames.macro <- list.files(paste0(root,ieem.folder,in.folder,"macro//"), pattern="*.csv", full.names=FALSE)

 files<-data.frame(meso=filenames.meso,
                   macro=filenames.meso)

#execute funtion
#this is the function
  var.names.file<-paste0(root,var.names.file.dir)
  census.data.file<-paste0(root,census.data.file.dir)
  va.data.file<-paste0(root,va.data.file.dir)
  tol<-0.25
  tolva<-0.25

#
#read all files
#test
#filename.macro <-  filenames.macro [1]
#filename.meso <-  filenames.meso [1]
#process.calib(filename.meso,filename.macro,var.names.file,census.data.file,va.data.file,tol,tolva)

#process all
   calib_results<-apply(files,1,function(x){process.calib(x['meso'],x['macro'],var.names.file,census.data.file,va.data.file,tol,tolva)})
   calib_results<-do.call('rbind',calib_results)

#write results
    write.csv(calib_results, paste0(root,ieem.folder,out.folder,"calib_results_2021_04_07.csv"), row.names=FALSE)


#lets post'process results
  #read calin file
  #identify futures that meet one or two of the targets
  #then subset futures to those ranges















####
#write function to process the files
 process.calib<-function(filename,tol){
   data<- read.csv(paste0(root,ieem.folder,in.folder,filename) )
   data<-subset(data,Scenario=='combi-rec5yr')[,c("Sector_Calib","Employment_rv_PctDiff","CensusEmployment_rv_PctDiff")]
   #tol<-0.25
   data$Tol_min<-(1-tol)*data$CensusEmployment_rv_PctDiff
   data$Tol_max<-(1+tol)*data$CensusEmployment_rv_PctDiff
   data$HitTarget<-ifelse(data$Employment_rv_PctDiff<=data$Tol_min & data$Employment_rv_PctDiff>=data$Tol_max,1,0 )
   data$Totalhits<-sum(data$HitTarget)
   data$run_id<-gsub("calib_report","",filename)
   data$run_id<-as.numeric(gsub(".csv","",data$run_id))
   data
   }

#read all files
   calib_results<-lapply(filenames,function(x){process.calib(x,0.25)})
   calib_results<-do.call('rbind',calib_results)

#write results
    write.csv(calib_results, paste0(root,ieem.folder,out.folder,"calib_results_2021_03_31.csv"), row.names=FALSE)
