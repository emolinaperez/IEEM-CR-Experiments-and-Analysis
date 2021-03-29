post_process_ieem<-function(dir.data,
                            dir.out,
                            run_id,
                            gams_version,
                            var.names.file,
                            census.data.file)
                            {
#post-process ieem results
#this script process ieem output
#post processing IEEM output
 library(reshape2)
 library(gdxdt)
 library(gdxrrw)
#igdx()
 igdx(gams_version)

 file.macro<-paste("repmacro2-cri2016rand_run-",run_id,".gdx",sep="")
 file.meso<-paste("repmeso2-cri2016rand_run-",run_id,".gdx",sep="")

#process macro report
 macro<-data.frame(readgdx(paste0(dir.data,file.macro),"macexprealyydol"))
  for (i in 1:3)
  {
    macro[,i]<-as.character(macro[,i])
  }
 colnames(macro)<-c("Scenario","Variable","Year","Value")
 macro<-reshape2::dcast(macro, Scenario + Year ~ Variable, value.var = "Value" )

#process meso report
 sheets<-c("employgrowthyy","qegrowthyy","qhgrowthyy","qmgrowthyy","qvagrowthyy")
 names<-c("Employment_gr","exports_gr","houselholds.cosumption_gr","imports_gr","value.added_gr")

#sheet 1
 meso<-data.frame(readgdx(paste0(dir.data,file.meso),sheets[1]))
 for (i in 1:3)
 {
 meso[,i]<-as.character(meso[,i])
 }
 colnames(meso)<-c("Scenario","Sector","Year",names[1])
 meso1<-meso
 meso1$Sector<-sapply(strsplit(meso1$Sector,"-",fixed=TRUE),"[",2)
 meso1$Sector<-ifelse(is.na(meso1$Sector)==TRUE,"total",meso1$Sector)

#sheet 2
 meso<-data.frame(readgdx(paste0(dir.data,file.meso),sheets[2]))
 for (i in 1:3)
 {
  meso[,i]<-as.character(meso[,i])
 }
 colnames(meso)<-c("Scenario","Sector","Year",names[2])
 meso2<-meso
 meso2$Sector<-sapply(strsplit(meso2$Sector,"-",fixed=TRUE),"[",2)
 meso2$Sector<-ifelse(is.na(meso2$Sector)==TRUE,"total",meso2$Sector)


#sheet 3
 meso<-data.frame(readgdx(paste0(dir.data,file.meso),sheets[3]))
 for (i in 1:4)
 {
  meso[,i]<-as.character(meso[,i])
 }
 colnames(meso)<-c("Scenario","Sector","HouselholdType","Year",names[3])
 meso3<-meso
 meso3<-subset(meso3,HouselholdType=='total')
 meso3<-meso3[,c("Scenario","Sector","Year",names[3])]
 meso3$Sector<-sapply(strsplit(meso3$Sector,"-",fixed=TRUE),"[",2)
 meso3$Sector<-ifelse(is.na(meso3$Sector)==TRUE,"total",meso3$Sector)

#sheet 4
 meso<-data.frame(readgdx(paste0(dir.data,file.meso),sheets[4]))
 for (i in 1:3)
 {
  meso[,i]<-as.character(meso[,i])
 }
 colnames(meso)<-c("Scenario","Sector","Year",names[4])
 meso4<-meso
 meso4$Sector<-sapply(strsplit(meso4$Sector,"-",fixed=TRUE),"[",2)
 meso4$Sector<-ifelse(is.na(meso4$Sector)==TRUE,"total",meso4$Sector)

#sheet 5
 meso<-data.frame(readgdx(paste0(dir.data,file.meso),sheets[5]))
 for (i in 1:3)
 {
  meso[,i]<-as.character(meso[,i])
 }
 colnames(meso)<-c("Scenario","Sector","Year",names[5])
 meso5<-meso
 meso5$Sector<-sapply(strsplit(meso5$Sector,"-",fixed=TRUE),"[",2)
 meso5$Sector<-ifelse(is.na(meso5$Sector)==TRUE,"total",meso5$Sector)

#merge all  data sets
 meso<-Reduce(function(...) { merge(..., all=TRUE) }, list(meso1,meso2,meso3,meso4,meso5))

#remove NAs
 for (i in 1:length(names))
 {
  meso[,names[i]]<-ifelse(is.na(meso[,names[i]])==TRUE,0,meso[,names[i]])
 }

#compute actual values
 meso0<-subset(meso,Year==2016)
 meso<-subset(meso,Year>2016)

 nnames<-gsub("gr","rv",names)
 mesof<-apply(
            meso0,1,function(x){
                                      pivot<-subset(meso,meso$Scenario==x['Scenario'] & meso$Sector==x['Sector']);
                                      pivot[,nnames[1]]<-cumprod(pivot[,names[1]]/100+1)*as.numeric(x[names[1]]);
                                      pivot[,nnames[2]]<-cumprod(pivot[,names[2]]/100+1)*as.numeric(x[names[2]]);
                                      pivot[,nnames[3]]<-cumprod(pivot[,names[3]]/100+1)*as.numeric(x[names[3]]);
                                      pivot[,nnames[4]]<-cumprod(pivot[,names[4]]/100+1)*as.numeric(x[names[4]]);
                                      pivot[,nnames[5]]<-cumprod(pivot[,names[5]]/100+1)*as.numeric(x[names[5]]);
                                      pivot
                                     }
           )

 mesof<-do.call('rbind',mesof)
 meso<-mesof
#add unemployment data to macro report
 unemployment<-data.frame(readgdx(paste0(dir.data,file.meso),"unemprate"))
 unemployment<-subset(unemployment,X.=="UERAT" & ac=="tot-lab")
 unemployment<-unemployment[,c("sim","t","value")]
 colnames(unemployment)<-c("Scenario","Year","Unemployment")
#merge macro report
 dim(macro)
  macro<-Reduce(function(...) { merge(..., all=TRUE) }, list(unemployment, macro))
 dim(macro)

#clean space before moving into next step
 rm(list=subset(ls(),!(ls()%in%c("dir.data", "macro","meso"))))

#compare simulation results against real data

# Include translation,

 snames<-read.csv(var.names.file)
#check all sectors are in code book
 subset(unique(meso$Sector),!(unique(meso$Sector)%in%unique(snames$Sector)))

#merge
 dim(meso)
 meso<-merge(meso,snames,by="Sector")
 dim(meso)

#let's first produce a table with baseline conditions
 ref<-subset(meso, Year==2019 & Scenario=='base')
 ref<-aggregate(ref[,"Employment_rv"],list(
                                             Scenario=ref$Scenario,
                                             Year=ref$Year,
                                             Sector_Calib=ref$Sector_Calib
                                             ),sum)
#
 ref$Employment_rv<-ref$x
 ref$x<-NULL

#now process real data and merge with results
  census<-read.csv(census.data.file)
  census$Employment_census<-census[,'Employment..people.']/1000
  census<-subset(census,Year==2019)
  census<-aggregate(census[,"Employment_census"],list(Sector_Calib=census$sector.en
                                                          ),sum)
  census$Employment_census<-census$x
  census$x<-NULL
#merge both
  dim(ref)
  dim(census)
  ref<-merge(ref,census,by='Sector_Calib',all.x=TRUE)
  dim(ref)

#now process the actual data
#aggregate employment per sector Calib
 meso<-aggregate(meso[,"Employment_rv"],list(
                                             Scenario=meso$Scenario,
                                             Year=meso$Year,
                                             Sector_Calib=meso$Sector_Calib
                                             ),sum)
meso$Employment_rv<-meso$x
meso$x<-NULL

#now create variable to compare against base
  meso.b<-subset(meso,Scenario=='base')
  meso.b$index<-paste0(meso.b$Sector_Calib,'_',meso.b$Year)
  meso.b<-meso.b[,c('index','Employment_rv')]
  colnames(meso.b)<-c('index','Employment_rv-B')
#create index in meso
  meso$index<-paste0(meso$Sector_Calib,'_',meso$Year)
  dim(meso)
  dim(meso.b)
  meso<-merge(meso,meso.b,by="index",all.x=TRUE)
  dim(meso)
  meso$index<-NULL

#just focus in 2020
  meso<-subset(meso,Year==2020)
  meso$Employment_rv_Diff<-meso[,'Employment_rv']-meso[,'Employment_rv-B']
  meso$Employment_rv_PctDiff<-(meso[,'Employment_rv']-meso[,'Employment_rv-B'])/meso[,'Employment_rv-B']


#i want to merge GDP decline
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

#write table
 write.csv(meso,paste(dir.out,"calib_report",run_id,".csv",sep=""),row.names=FALSE)
 }
