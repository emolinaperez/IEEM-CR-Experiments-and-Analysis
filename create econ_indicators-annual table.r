#create reference hw and lw numbers by gender

#read the varcodes

 snames<- read.csv("C:\\Users\\Usuario\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-CR-Experiments-and-Analysis\\Vars_Code_v3.csv")
 snamestypes<-reshape2::dcast(snames,Sector_Calib~ wtype)
 snamestypes$total<-snamestypes$lw+snamestypes$hw
 snamestypes$lw<-snamestypes$lw/snamestypes$total
 snamestypes$hw<-snamestypes$hw/snamestypes$total
 snamestypes<-subset(snamestypes,Sector_Calib!="total")
 snamestypes$total<-NULL

 #read census data
  census<- read.csv("C:\\Users\\Usuario\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-CR-Experiments-and-Analysis\\Unemployment by sector 2010 - 2020_juan_gender_columns.csv")

#agregate wtype to census
 dim(census)
 dim(snamestypes)
 census<-merge(census,unique(snamestypes[c("Sector_Calib","lw","hw")]),by="Sector_Calib")
 dim(census)

#create gender columns
  census$elw<-census[,"Employment..people."]*census$lw
  census$ehw<-census[,"Employment..people."]*census$hw

#create aggreate tables
#low wage table
 a1<-aggregate(list(Employment=census$elw),list(Year=census$Year, Gender=census$Gender),sum)
 a1[,"GDP growth [percent]"]<-0
 a1[,"Unemployment [percent]"]<-0
 a1[,"Employment [people]"]<-a1$Employment
 a1$sector<-paste0("lw-",a1$Gender)
 a1$class<-paste0("lw-",a1$Gender)
 a1[,"sector-en"]<-paste0("lw-",a1$Gender)
 a1[,"class-en"]<-paste0("lw-",a1$Gender)
 a1$Gender<-NULL
 a1$Employment<-NULL

#high wage table
 a2<-aggregate(list(Employment=census$ehw),list(Year=census$Year, Gender=census$Gender),sum)
 a2[,"GDP growth [percent]"]<-0
 a2[,"Unemployment [percent]"]<-0
 a2[,"Employment [people]"]<-a2$Employment
 a2$sector<-paste0("hw-",a2$Gender)
 a2$class<-paste0("hw-",a2$Gender)
 a2[,"sector-en"]<-paste0("hw-",a2$Gender)
 a2[,"class-en"]<-paste0("hw-",a2$Gender)
 a2$Gender<-NULL
 a2$Employment<-NULL

#rbind both
 a<-rbind(a1,a2)
 subset(a,Year%in%c(2019,2020))


#read the original data
 econIndicators<- read.csv("C:\\Users\\Usuario\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-CR-Experiments-and-Analysis\\econ_indicators-annual_2010-2020_new.csv")
 colnames(econIndicators)<-c("Year","GDP growth [percent]","Unemployment [percent]","Employment [people]","sector","class","sector-en","class-en")
#rbind the a table
 econIndicators<-rbind(econIndicators,a)

#write.csv
 write.csv(econIndicators, paste0("C:\\Users\\Usuario\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-CR-Experiments-and-Analysis\\","econ_indicators-annual_2010-2020_new_by_gender_updated.csv"), row.names=FALSE)


#
 test<-subset(a,Year%in%c(2019,2020))
 test<-reshape2::dcast(test,sector~ Year,value.var="Employment [people]")
 test$Ediff<-test[,"2020"]-test[,"2019"]


unique(snames$Sector_Calib)
unique(census$Sector_Calib)

#logical test
subset(unique(census$Sector_Calib),!(unique(census$Sector_Calib)%in%unique(snames$Sector_Calib)))
subset(unique(snames$Sector_Calib),!(unique(snames$Sector_Calib)%in%unique(census$Sector_Calib)))
