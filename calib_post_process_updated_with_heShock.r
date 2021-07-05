#load process function
 process.calib<-function(filename.meso,
                         filename.macro,
                         var.names.file,
                         census.data.file,
                         va.data.file,
                         tol,
                         tolva
                         ) {

#read file
#  filename.meso<-  filenames.meso [322]
  meso<- read.csv(paste0(root,ieem.folder,in.folder,"meso//",filename.meso) )

# Include translation,
  snames<-read.csv(var.names.file)
##check all sectors are in code book
  subset(unique(meso$Sector),!(unique(meso$Sector)%in%unique(snames$Sector)))

#merge
 dim(meso)
 meso<-merge(meso,snames,by="Sector")
 dim(meso)

#create categories for low, high wages and gender partitions
 mesoB<-meso
 mesoB$Employment_rvf<-mesoB$Employment_rv*mesoB$f
 mesoB$Employment_rvm<-mesoB$Employment_rv*mesoB$m
 mesoB$value.added_rvf<-mesoB$value.added_rv*mesoB$f
 mesoB$value.added_rvm<-mesoB$value.added_rv*mesoB$m

#females
 mesoB_female<-aggregate(mesoB[,c("Employment_rvf","value.added_rvf")],list(
                                             Scenario=mesoB$Scenario,
                                             Year=mesoB$Year,
                                             wtype=mesoB$wtype
                                             ),sum)
 mesoB_female$Sector_Calib<-paste0(mesoB_female$wtype,"-female")
 mesoB_female<-mesoB_female[,c("Scenario","Year","Sector_Calib","Employment_rvf","value.added_rvf")]
 colnames(mesoB_female)<-c("Scenario","Year","Sector_Calib","Employment_rv","value.added_rv")

#males
 mesoB_male<-aggregate(mesoB[,c("Employment_rvm","value.added_rvm")],list(
                                            Scenario=mesoB$Scenario,
                                            Year=mesoB$Year,
                                            wtype=mesoB$wtype
                                            ),sum)
 mesoB_male$Sector_Calib<-paste0(mesoB_male$wtype,"-male")
 mesoB_male<-mesoB_male[,c("Scenario","Year","Sector_Calib","Employment_rvm","value.added_rvm")]
 colnames(mesoB_male)<-c("Scenario","Year","Sector_Calib","Employment_rv","value.added_rv")

#
#now process the actual data
#aggregate employment per sector Calib
 meso<-aggregate(meso[,c("Employment_rv","value.added_rv")],list(
                                             Scenario=meso$Scenario,
                                             Year=meso$Year,
                                             Sector_Calib=meso$Sector_Calib
                                             ),sum)
#meso$Employment_rv<-meso$x
#meso$x<-NULL

#rbind
 meso<-rbind(meso,mesoB_female,mesoB_male)


 #add simulated impact on home-employees
 #
 dataT<-subset(meso,Sector_Calib=="Home employees")
 metrics<-c("Employment_rv","houselholds.cosumption_rv","value.added_rv")
 ids<-c()

#employment
  pivot<-dataT[,c(ids,"Year","Scenario",metrics[1])]
  new.form<-as.formula(paste0("Year","~","Scenario"))
  pivot<-reshape2::dcast(pivot,new.form, value.var=metrics[1])
  pivot[,paste0("Delta_",metrics[1])]<-pivot$base-pivot[,"combi-rec5yr"]
  pivot[,paste0("Delta_",metrics[1])]<-ifelse( pivot[,paste0("Delta_",metrics[1])]<0,0, pivot[,paste0("Delta_",metrics[1])])
  pivot$base<-NULL
  pivot[,"combi-rec5yr"]<-NULL

#value.added rv
 pivot1<-dataT[,c(ids,"Year","Scenario",metrics[3])]
 new.form<-as.formula(paste0("Year","~","Scenario"))
 pivot1<-reshape2::dcast(pivot1,new.form, value.var=metrics[3])
 pivot1[,paste0("Delta_",metrics[3])]<-pivot1$base-pivot1[,"combi-rec5yr"]
 pivot1$base<-NULL
 pivot1[,"combi-rec5yr"]<-NULL

#merge all
 dim(pivot)
 dim(pivot1)
 pivot<-Reduce(function(...) { merge(...) }, list(pivot,pivot1))
 dim(pivot)

#ratio thing
 pivot$ratio<-pivot$Delta_value.added_rv/pivot$Delta_Employment_rv
 pivot$ratio<-ifelse(pivot$Delta_Employment_rv==0,0,pivot$ratio)

#ok, so let's simulate the impact
 scale<-2.0 #higher values of scale, are higher impacts
 pivot$Eimpact<-scale*pivot$Delta_Employment_rv
 pivot$VAimpact<-pivot$Eimpact*pivot$ratio
 pivot$VAimpact<-ifelse(is.na(pivot$VAimpact)==TRUE,0,pivot$VAimpact)
 pivot$Scenario<-"combi-rec5yr"
 pivot<-pivot[,c(ids,"Year","Scenario","Eimpact","VAimpact")]

#add base scenario
 pivotb<-pivot
 pivotb$Scenario<-"base"
 pivotb$Eimpact<-0
  pivotb$VAimpact<-0
 pivot<-rbind(pivot,pivotb)


#merge pivot with the original data set, and adjust impact sector by sector
 dim(meso)
 dim(pivot)
  meso<-Reduce(function(...) { merge(...) }, list(meso,pivot))
 dim(meso)

 #
# summary(subset(data,Scenario=="base"))

#employment adjustment
meso$Employment_rv_new<-ifelse(meso$Sector_Calib=="Home employees",meso$Employment_rv-meso$Eimpact,
                           ifelse(meso$Sector_Calib=="lw-female",meso$Employment_rv-meso$Eimpact*0.9,
                                ifelse(meso$Sector_Calib=="lw-male",meso$Employment_rv-meso$Eimpact*0.1,meso$Employment_rv-meso$Eimpact*0.005)
                                  )
                               )


#value added adjustment
#base does chnage
meso$value.added_rv_new<-ifelse(meso$Sector_Calib=="Home employees",meso$value.added_rv-meso$VAimpact,
                           ifelse(meso$Sector_Calib=="lw-female",meso$value.added_rv-meso$VAimpact*0.81,
                                ifelse(meso$Sector_Calib=="lw-male",meso$value.added_rv-meso$VAimpact*0.19,meso$value.added_rv-meso$VAimpact*0.004)
                                  )
                               )

#re estimate totals
 test<-subset(meso,!(Sector_Calib%in%c("total","lw-female","lw-male","hw-female","hw-male")))

#for employment
newTotals<-aggregate(test[,c("Employment_rv","Employment_rv_new")],test[,c("Scenario","Year")],sum)
newTotals$Employment_rv_newNT<-newTotals$Employment_rv_new
newTotals$Employment_rv_new<-NULL
newTotals$Employment_rv<-NULL

#merge with original
 dim(meso)
 dim(newTotals)
  meso<-Reduce(function(...) { merge(...) }, list(meso,newTotals))
 dim(meso)

#make adjustment for total
 meso$Employment_rv_new<-ifelse(meso$Sector_Calib=="total",meso$Employment_rv_newNT,meso$Employment_rv_new)

#for value added
 newTotalsVA<-aggregate(test[,c("value.added_rv","value.added_rv_new")],test[,c("Scenario","Year")],sum)
 newTotalsVA$value.added_rv_newNT<-newTotalsVA$value.added_rv_new
 newTotalsVA$value.added_rv_new<-NULL
 newTotalsVA$value.added_rv<-NULL

 #merge with original
  dim(meso)
  dim(newTotalsVA)
   meso<-Reduce(function(...) { merge(...) }, list(meso,newTotalsVA))
  dim(meso)

 #make adjustment for total
  meso$value.added_rv_new<-ifelse(meso$Sector_Calib=="total",meso$value.added_rv_newNT,meso$value.added_rv_new)

#make final change for both variables
 meso$Employment_rv<-meso$Employment_rv_new
 meso$value.added_rv<-meso$value.added_rv_new

#eliminate unwanted columns
 meso$Eimpact <- NULL
 meso$VAimpact <- NULL
 meso$Employment_rv_new <- NULL
 meso$value.added_rv_new <- NULL
 meso$Employment_rv_newNT <- NULL
 meso$value.added_rv_newNT <- NULL


#add total- home employees here
 meso.dummy<-subset(meso,Sector_Calib=='total')
 meso.dummyhe<-subset(meso,Sector_Calib=='Home employees')
 meso.dummyhe$Employment_rvhe<-meso.dummyhe$Employment_rv
 meso.dummyhe$value.added_rvhe<-meso.dummyhe$value.added_rv
 meso.dummyhe<-meso.dummyhe[,c('Scenario','Year','Employment_rvhe','value.added_rvhe')]
 meso.dummy<-Reduce(function(...) { merge(..., all=TRUE) }, list(meso.dummy, meso.dummyhe))
 meso.dummy$Employment_rv<-meso.dummy$Employment_rv-meso.dummy$Employment_rvhe
 meso.dummy$value.added_rv<-meso.dummy$value.added_rv-meso.dummy$value.added_rvhe
 meso.dummy$Sector_Calib<-'total minus households'
 meso.dummy$Employment_rvhe<-NULL
 meso.dummy$value.added_rvhe<-NULL

#rbind
 meso<-rbind(meso,meso.dummy)

#add low wage and high wage
 #meso<-rbind(meso,mesoB_female,mesoB_male)

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
#  filename.macro <-  filenames.macro [323]
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
 meso<-subset(meso,Scenario=='combi-rec5yr')[,c("Sector_Calib",
                                                "Employment_rv_PctDiff",
                                                "Employment_rv_Diff",
                                                "CensusEmployment_rv_PctDiff",
                                                "CensusEmployment_rv_Diff",
                                                "value.added_rv_Diff",
                                                "value.added_rv_PctDiff",
                                                "CensusValueAdded_rv_PctDiff",
                                                "CensusValueAdded_rv_Diff"
                                               )]
#set tolerance for employment
 #meso$Tol_min<-(1-tol)*meso$CensusEmployment_rv_PctDiff
 #meso$Tol_max<-(1+tol)*meso$CensusEmployment_rv_PctDiff
 meso$Tol_min<-meso$CensusEmployment_rv_PctDiff-tol
 meso$Tol_max<-meso$CensusEmployment_rv_PctDiff+tol
#set tolerance for added value
 #meso$Tolva_min<-(1-tolva)*meso$CensusValueAdded_rv_PctDiff
 #meso$Tolva_max<-(1+tolva)*meso$CensusValueAdded_rv_PctDiff
 meso$Tolva_min<-meso$CensusValueAdded_rv_PctDiff-tolva
 meso$Tolva_max<-meso$CensusValueAdded_rv_PctDiff+tolva

#identify whether or not the simulation meets the target
#employment
# meso$HitTarget<-ifelse(meso$Employment_rv_PctDiff<=meso$Tol_min & meso$Employment_rv_PctDiff>=meso$Tol_max,1,0 )
 meso$HitTarget<-ifelse(meso$Employment_rv_PctDiff>=meso$Tol_min & meso$Employment_rv_PctDiff<=meso$Tol_max,1,0 )
 meso$Totalhits<-sum(meso$HitTarget)
#value added
# meso$HitTargetVa<-ifelse(meso$value.added_rv_PctDiff<=meso$Tolva_min & meso$value.added_rv_PctDiff>=meso$Tolva_max,1,0 )
 meso$HitTargetVa<-ifelse(meso$value.added_rv_PctDiff>=meso$Tolva_min & meso$value.added_rv_PctDiff<=meso$Tolva_max,1,0 )
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

#set parameters
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
  in.folder<-"calib_results\\" #part 4
 #in.folder<-"calib_results_2021_04_08\\" #part 3
 #in.folder<-"calib_results_2021_04_06\\" #part 2
 #in.folder<-"calib_results_2021_04_01\\" #part 1
 out.folder<-"calib_result_all\\"
 var.names.file.dir<-"IEEM-CR-Experiments-and-Analysis\\Vars_Code_v3.csv"
 census.data.file.dir<-"IEEM-CR-Experiments-and-Analysis\\econ_indicators-annual_2010-2020_new_by_gender.csv"
 va.data.file.dir<-"IEEM-CR-Experiments-and-Analysis\\value_added-annual_2010-2020_new_by_gender.csv"

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
  #tol<-0.25
  #tolva<-0.25
  tol<-0.025
  tolva<-0.025


#process all
#   calib_results<-apply(files,1,function(x){process.calib(x['meso'],x['macro'],var.names.file,census.data.file,va.data.file,tol,tolva)})
#   calib_results<-do.call('rbind',calib_results)

#write results
#    write.csv(calib_results, paste0(root,ieem.folder,out.folder,"calib_results_2021_04_07.csv"), row.names=FALSE)


#read all parts and rbind for viz file
#part 1
 in.folder<-"calib_results_2021_04_01\\" #part 1
 # read list of files
    filenames.meso <- list.files(paste0(root,ieem.folder,in.folder,"meso//"), pattern="*.csv", full.names=FALSE)
    filenames.macro <- list.files(paste0(root,ieem.folder,in.folder,"macro//"), pattern="*.csv", full.names=FALSE)

  files<-data.frame(meso=filenames.meso,
                    macro=filenames.meso)

 calib_results<-apply(files,1,function(x){process.calib(x['meso'],x['macro'],var.names.file,census.data.file,va.data.file,tol,tolva)})
 calib_results<-do.call('rbind',calib_results)
 calib_resultsp1<-calib_results
 length(unique(calib_resultsp1$Run.id))
 summary(unique(calib_resultsp1$Run.id))
#
#part 2
 in.folder<-"calib_results_2021_04_06\\" #part 2
 # read list of files
    filenames.meso <- list.files(paste0(root,ieem.folder,in.folder,"meso//"), pattern="*.csv", full.names=FALSE)
    filenames.macro <- list.files(paste0(root,ieem.folder,in.folder,"macro//"), pattern="*.csv", full.names=FALSE)

  files<-data.frame(meso=filenames.meso,
                    macro=filenames.meso)

 calib_results<-apply(files,1,function(x){process.calib(x['meso'],x['macro'],var.names.file,census.data.file,va.data.file,tol,tolva)})
 calib_results<-do.call('rbind',calib_results)
 calib_resultsp2<-calib_results
 calib_resultsp2$Run.id<-calib_resultsp2$Run.id+400*1
 length(unique(calib_resultsp2$Run.id))
 summary(unique(calib_resultsp2$Run.id))
#
#part 3
 in.folder<-"calib_results_2021_04_08\\" #part 3
 # read list of files
    filenames.meso <- list.files(paste0(root,ieem.folder,in.folder,"meso//"), pattern="*.csv", full.names=FALSE)
    filenames.macro <- list.files(paste0(root,ieem.folder,in.folder,"macro//"), pattern="*.csv", full.names=FALSE)

  files<-data.frame(meso=filenames.meso,
                    macro=filenames.meso)

 calib_results<-apply(files,1,function(x){process.calib(x['meso'],x['macro'],var.names.file,census.data.file,va.data.file,tol,tolva)})
 calib_results<-do.call('rbind',calib_results)
 calib_resultsp3<-calib_results
 calib_resultsp3$Run.id<-calib_resultsp3$Run.id+400*2
 length(unique(calib_resultsp3$Run.id))
 summary(unique(calib_resultsp3$Run.id))

#
#part 4
 in.folder<-"calib_results_2021_04_10\\" #part 4
 # read list of files
    filenames.meso <- list.files(paste0(root,ieem.folder,in.folder,"meso//"), pattern="*.csv", full.names=FALSE)
    filenames.macro <- list.files(paste0(root,ieem.folder,in.folder,"macro//"), pattern="*.csv", full.names=FALSE)

  files<-data.frame(meso=filenames.meso,
                    macro=filenames.meso)

 calib_results<-apply(files,1,function(x){process.calib(x['meso'],x['macro'],var.names.file,census.data.file,va.data.file,tol,tolva)})
 calib_results<-do.call('rbind',calib_results)
 calib_resultsp4<-calib_results
 calib_resultsp4$Run.id<-calib_resultsp4$Run.id+400*3
 length(unique(calib_resultsp4$Run.id))
 summary(unique(calib_resultsp4$Run.id))

 #part 5
  in.folder<-"calib_results_2021_04_11\\" #part 5
  # read list of files
     filenames.meso <- list.files(paste0(root,ieem.folder,in.folder,"meso//"), pattern="*.csv", full.names=FALSE)
     filenames.macro <- list.files(paste0(root,ieem.folder,in.folder,"macro//"), pattern="*.csv", full.names=FALSE)

   files<-data.frame(meso=filenames.meso,
                     macro=filenames.meso)

  calib_results<-apply(files,1,function(x){process.calib(x['meso'],x['macro'],var.names.file,census.data.file,va.data.file,tol,tolva)})
  calib_results<-do.call('rbind',calib_results)
  calib_resultsp5<-calib_results
  calib_resultsp5$Run.id<-calib_resultsp5$Run.id+ max(unique(calib_resultsp4$Run.id))
  length(unique(calib_resultsp5$Run.id))
  summary(unique(calib_resultsp5$Run.id))

#
#part 6
 in.folder<-"calib_results_2021_04_12_p1\\" #part 6
 # read list of files
    filenames.meso <- list.files(paste0(root,ieem.folder,in.folder,"meso//"), pattern="*.csv", full.names=FALSE)
    filenames.macro <- list.files(paste0(root,ieem.folder,in.folder,"macro//"), pattern="*.csv", full.names=FALSE)

  files<-data.frame(meso=filenames.meso,
                    macro=filenames.meso)

 calib_results<-apply(files,1,function(x){process.calib(x['meso'],x['macro'],var.names.file,census.data.file,va.data.file,tol,tolva)})
 calib_results<-do.call('rbind',calib_results)
 calib_resultsp6<-calib_results
 calib_resultsp6$Run.id<-calib_resultsp6$Run.id+ max(unique(calib_resultsp5$Run.id))
 length(unique(calib_resultsp6$Run.id))
 summary(unique(calib_resultsp6$Run.id))

#
#part 7
 in.folder<-"calib_results_2021_04_12_p2\\" #part 7
 # read list of files
    filenames.meso <- list.files(paste0(root,ieem.folder,in.folder,"meso//"), pattern="*.csv", full.names=FALSE)
    filenames.macro <- list.files(paste0(root,ieem.folder,in.folder,"macro//"), pattern="*.csv", full.names=FALSE)

  files<-data.frame(meso=filenames.meso,
                    macro=filenames.meso)

 calib_results<-apply(files,1,function(x){process.calib(x['meso'],x['macro'],var.names.file,census.data.file,va.data.file,tol,tolva)})
 calib_results<-do.call('rbind',calib_results)
 calib_resultsp7<-calib_results
 calib_resultsp7$Run.id<-calib_resultsp7$Run.id+ max(unique(calib_resultsp6$Run.id))
 length(unique(calib_resultsp7$Run.id))
 summary(unique(calib_resultsp7$Run.id))

#
#part 8
 in.folder<-"calib_results_2021_04_12_p3\\" #part 8
 # read list of files
    filenames.meso <- list.files(paste0(root,ieem.folder,in.folder,"meso//"), pattern="*.csv", full.names=FALSE)
    filenames.macro <- list.files(paste0(root,ieem.folder,in.folder,"macro//"), pattern="*.csv", full.names=FALSE)

  files<-data.frame(meso=filenames.meso,
                    macro=filenames.meso)

 calib_results<-apply(files,1,function(x){process.calib(x['meso'],x['macro'],var.names.file,census.data.file,va.data.file,tol,tolva)})
 calib_results<-do.call('rbind',calib_results)
 calib_resultsp8<-calib_results
 calib_resultsp8$Run.id<-calib_resultsp8$Run.id+ max(unique(calib_resultsp7$Run.id))
 length(unique(calib_resultsp8$Run.id))
 summary(unique(calib_resultsp8$Run.id))

#
#part 9
 in.folder<-"calib_results_2021_04_12_p4\\" #part 9
 # read list of files
    filenames.meso <- list.files(paste0(root,ieem.folder,in.folder,"meso//"), pattern="*.csv", full.names=FALSE)
    filenames.macro <- list.files(paste0(root,ieem.folder,in.folder,"macro//"), pattern="*.csv", full.names=FALSE)

  files<-data.frame(meso=filenames.meso,
                    macro=filenames.meso)

 calib_results<-apply(files,1,function(x){process.calib(x['meso'],x['macro'],var.names.file,census.data.file,va.data.file,tol,tolva)})
 calib_results<-do.call('rbind',calib_results)
 calib_resultsp9<-calib_results
 calib_resultsp9$Run.id<-calib_resultsp9$Run.id+ max(unique(calib_resultsp8$Run.id))
 length(unique(calib_resultsp9$Run.id))
 summary(unique(calib_resultsp9$Run.id))




#add run  0
 calib_resultsp0<-subset( calib_resultsp1,Run.id==1)
 calib_resultsp0$Employment_rv_PctDiff<-calib_resultsp0$CensusEmployment_rv_PctDiff
 calib_resultsp0$value.added_rv_PctDiff<-calib_resultsp0$CensusValueAdded_rv_PctDiff
 calib_resultsp0$Employment_rv_Diff<-calib_resultsp0$CensusEmployment_rv_Diff
 calib_resultsp0$value.added_rv_Diff<-calib_resultsp0$CensusValueAdded_rv_Diff

 calib_resultsp0[,c('Tol_min','Tol_max','Tolva_min','Tolva_max','HitTarget','Totalhits','HitTargetVa','Totalhitsva','HitTargetBoth','TotalhitsBoth','TotalIndhits')]<-0
 calib_resultsp0$Run.id<-0

#rbind all
 calib_results_final<-rbind(calib_resultsp0,calib_resultsp1,calib_resultsp2,calib_resultsp3,calib_resultsp4,calib_resultsp5,calib_resultsp6,calib_resultsp7,calib_resultsp8,calib_resultsp9)
 length(unique(calib_results_final$Run.id))
 summary(unique(calib_results_final$Run.id))

#write file
 #write.csv(calib_results_final, paste0(root,ieem.folder,out.folder,"calib_results_2021_06_10.csv"), row.names=FALSE)
 write.csv(calib_results_final, paste0(root,ieem.folder,out.folder,"calib_results.csv"), row.names=FALSE)



#
#read all files
#test
#filename.macro <-  filenames.macro [1]
#filename.meso <-  filenames.meso [1]
#process.calib(filename.meso,filename.macro,var.names.file,census.data.file,va.data.file,tol,tolva)


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
  #  write.csv(calib_results, paste0(root,ieem.folder,out.folder,"calib_results_2021_03_31.csv"), row.names=FALSE)
  write.csv(calib_results, paste0(root,ieem.folder,out.folder,"calib_results.csv"), row.names=FALSE)
