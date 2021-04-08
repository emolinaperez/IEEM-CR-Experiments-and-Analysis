#create baseline comparison
#in pc
   root<-"C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\"
   ieem.folder<-"IEEM-en-GAMS-with-EXCAP-2021-01-25\\"
   in.folder<-"calib_results\\"
   out.folder<-"IEEM-CR-Experiments-and-Analysis\\"
   var.names.file.dir<-"IEEM-CR-Experiments-and-Analysis\\Vars_Code_v2.csv"
   census.data.file.dir<-"IEEM-CR-Experiments-and-Analysis\\econ_indicators-annual_2010-2020_new.csv"
   va.data.file.dir<-"IEEM-CR-Experiments-and-Analysis\\value_added-annual_2010-2020_new.csv"
   var.names.file<-paste0(root,var.names.file.dir)
   census.data.file<-paste0(root,census.data.file.dir)
   va.data.file<-paste0(root,va.data.file.dir)


#lets do the comparison for both employment and value added
   filenames.meso <- list.files(paste0(root,ieem.folder,in.folder,"meso//"), pattern="*.csv", full.names=FALSE)
   filename.meso<-  filenames.meso [1]
   meso<- read.csv(paste0(root,ieem.folder,in.folder,"meso//",filename.meso) )

# Include translation,
  snames<-read.csv(var.names.file)
##check all sectors are in code book
  subset(unique(meso$Sector),!(unique(meso$Sector)%in%unique(snames$Sector)))

#merge
 dim(meso)
 meso<-merge(meso,snames,by="Sector")
 dim(meso)

#let's first produce a table with baseline conditions
#for employment
 ref<-subset(meso, Year==2019 & Scenario=='base')
 ref<-aggregate(ref[,"Employment_rv"],list(
                                             Scenario=ref$Scenario,
                                             Year=ref$Year,
                                             Sector_Calib=ref$Sector_Calib
                                             ),sum)

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


#for value added
 refva<-subset(meso, Year==2019 & Scenario=='base')
 refva<-aggregate(refva[,"value.added_rv"],list(
                                             Scenario=refva$Scenario,
                                             Year=refva$Year,
                                             Sector_Calib=refva$Sector_Calib
                                             ),sum)

 refva$value.added_rv<-refva$x
 refva$x<-NULL
#now process real data and merge with results
   census.va<-read.csv(va.data.file)
   census.va$ValueAdded_census<-census.va[,'Billions.of.colones_deflated']
   census.va<-subset(census.va,Year==2019)
   census.va<-aggregate(census.va[,"ValueAdded_census"],list(Sector_Calib=census.va$Sector_Calib
                                                           ),sum)
   census.va$ValueAdded_census<-census.va$x
   census.va$x<-NULL
 #merge both
  dim(refva)
  dim(census.va)
   refva<-merge(refva,census.va,by='Sector_Calib',all.x=TRUE)
  dim(refva)

#I assume home employees falls inside "Commerce, repairs,professional and administrative activities"
 he.ratio<-refva$value.added_rv[refva$Sector_Calib=='Home employees']/refva$value.added_rv[refva$Sector_Calib=='Commerce, repairs,professional and administrative activities']
 refva$ValueAdded_census[refva$Sector_Calib=='Home employees']<-he.ratio*refva$ValueAdded_census[refva$Sector_Calib=='Commerce, repairs,professional and administrative activities']
 refva$ValueAdded_census[refva$Sector_Calib=='Commerce, repairs,professional and administrative activities']<-(1-he.ratio)*refva$ValueAdded_census[refva$Sector_Calib=='Commerce, repairs,professional and administrative activities']

#merge all
 ref_all<-Reduce(function(...) { merge(..., all=TRUE) }, list(ref, refva))
 write.csv(ref_all, paste0(root,out.folder,"reference_table_2021_04_02.csv"), row.names=FALSE)
