#this script simulates home employees shock

#root<-"C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-01-25\\investment_result_all\\data on may 23\\"
#root<-"C:\\Users\\Usuario\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-01-25\\investment_result_all\\data on may 23\\"
root<-"C:\\Users\\Usuario\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-01-25\\investment_result_all\\"
#file.name<-"meso_report_2021_05_23_wSouthPole.csv"
file.name<-"meso_report_2021_06_22.csv" #"meso_report_2021_06_15.csv"

data<-read.csv(paste(root,file.name,sep=""))

dataT<-subset(data,Sector=="domest")

metrics<-c("Employment_rv","houselholds.cosumption_rv","value.added_rv")


ids<-c("covid.shock","investment.shock","calib.run","shock.type")


#employment
 pivot<-dataT[,c(ids,"Year","Scenario",metrics[1])]
 new.form<-as.formula(paste0(paste(ids,collapse="+"),"+Year","~","Scenario"))
 pivot<-reshape2::dcast(pivot,new.form, value.var=metrics[1])
 pivot[,paste0("Delta_",metrics[1])]<-pivot$base-pivot$invest1yr
 pivot[,paste0("Delta_",metrics[1])]<-ifelse( pivot[,paste0("Delta_",metrics[1])]<0 & pivot$investment.shock%in%c("scenario 0","scenario 0-updated")==TRUE,0, pivot[,paste0("Delta_",metrics[1])])
 pivot$base<-NULL
 pivot$invest1yr<-NULL

#value.added rv
 pivot1<-dataT[,c(ids,"Year","Scenario",metrics[3])]
 new.form<-as.formula(paste0(paste(ids,collapse="+"),"+Year","~","Scenario"))
 pivot1<-reshape2::dcast(pivot1,new.form, value.var=metrics[3])
 pivot1[,paste0("Delta_",metrics[3])]<-pivot1$base-pivot1$invest1yr
 pivot1$base<-NULL
 pivot1$invest1yr<-NULL

#merge all
 dim(pivot)
 dim(pivot1)
 pivot<-Reduce(function(...) { merge(...) }, list(pivot,pivot1))
 dim(pivot)

#ratio thing
 pivot$ratio<-pivot$Delta_value.added_rv/pivot$Delta_Employment_rv
 pivot$ratio<-ifelse(pivot$Delta_Employment_rv==0,0,pivot$ratio)

#ok, so let's simulate the impact
 scale<-2.0
 pivot$Eimpact<-scale*pivot$Delta_Employment_rv
 pivot$VAimpact<-pivot$Eimpact*pivot$ratio
 pivot$VAimpact<-ifelse(is.na(pivot$VAimpact)==TRUE,0,pivot$VAimpact)
 pivot$Scenario<-"invest1yr"
 pivot<-pivot[,c(ids,"Year","Scenario","Eimpact","VAimpact")]

#add base scenario
 pivotb<-pivot
 pivotb$Scenario<-"base"
 pivotb$Eimpact<-0
  pivotb$VAimpact<-0
 pivot<-rbind(pivot,pivotb)

#merge pivot with the original data set, and adjust impact sector by sector
 dim(data)
 dim(pivot)
  data<-Reduce(function(...) { merge(...) }, list(data,pivot))
 dim(data)

 #
# summary(subset(data,Scenario=="base"))

#employment adjustment
data$Employment_rv_new<-ifelse(data$Sector=="domest",data$Employment_rv-data$Eimpact,
                           ifelse(data$Sector=="lw-female",data$Employment_rv-data$Eimpact*0.9,
                                ifelse(data$Sector=="lw-male",data$Employment_rv-data$Eimpact*0.1,data$Employment_rv-data$Eimpact*0.005)
                                  )
                               )


#value added adjustment
#base does chnage
data$value.added_rv_new<-ifelse(data$Sector=="domest",data$value.added_rv-data$VAimpact,
                           ifelse(data$Sector=="lw-female",data$value.added_rv-data$VAimpact*0.81,
                                ifelse(data$Sector=="lw-male",data$value.added_rv-data$VAimpact*0.19,data$value.added_rv-data$VAimpact*0.004)
                                  )
                               )

#re estimate totals
 test<-subset(data,!(Sector%in%c("total","lw-female","lw-male","hw-female","hw-male")))

#for employment
newTotals<-aggregate(test[,c("Employment_rv","Employment_rv_new")],test[,c("Scenario","Year","covid.shock","investment.shock","calib.run","shock.type","Run.id")],sum)
newTotals$Employment_rv_newNT<-newTotals$Employment_rv_new
newTotals$Employment_rv_new<-NULL
newTotals$Employment_rv<-NULL

#merge with original
 dim(data)
 dim(newTotals)
  data<-Reduce(function(...) { merge(...) }, list(data,newTotals))
 dim(data)

#make adjustment for total
 data$Employment_rv_new<-ifelse(data$Sector=="total",data$Employment_rv_newNT,data$Employment_rv_new)

#for value added
 newTotalsVA<-aggregate(test[,c("value.added_rv","value.added_rv_new")],test[,c("Scenario","Year","covid.shock","investment.shock","calib.run","shock.type","Run.id")],sum)
 newTotalsVA$value.added_rv_newNT<-newTotalsVA$value.added_rv_new
 newTotalsVA$value.added_rv_new<-NULL
 newTotalsVA$value.added_rv<-NULL

 #merge with original
  dim(data)
  dim(newTotalsVA)
   data<-Reduce(function(...) { merge(...) }, list(data,newTotalsVA))
  dim(data)

 #make adjustment for total
  data$value.added_rv_new<-ifelse(data$Sector=="total",data$value.added_rv_newNT,data$value.added_rv_new)

#make final change for both variables
 data$Employment_rv<-data$Employment_rv_new
 data$value.added_rv<-data$value.added_rv_new

#eliminate unwanted columns
 data$Eimpact <- NULL
 data$VAimpact <- NULL
 data$Employment_rv_new <- NULL
 data$value.added_rv_new <- NULL
 data$Employment_rv_newNT <- NULL
 data$value.added_rv_newNT <- NULL

#write new file
 #write.csv(data,"meso_report.csv",row.names=FALSE)


#create table 3.1
 t3<-subset(data,investment.shock=="scenario 0")
 t3<-subset(t3,Sector%in%c("lw-female","lw-male","hw-female","hw-male"))
 t3<-subset(t3,Year%in%c(2019,2020,2025))

 write.csv(t3,"tables_chaper3.csv",row.names=FALSE)



#create simulated test for final chapter example

data1<-read.csv("C:\\Users\\Usuario\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-01-25\\investment_result_all\\data on june 22\\meso_report_2021_06_22.csv")

#ids<-c("Sector","Scenario","Year","covid.shock","investment.shock","calib.run","shock.type")
ids<-c("Sector","Scenario","covid.shock","investment.shock","calib.run","shock.type")
vars<-c("Employment_rv")

shocks<-unique(data1$investment.shock)

 delta<-subset(data1,investment.shock==shocks[1])
 delta2020<-subset(delta,Year==2020)
 delta2020$E2020<-delta2020[,vars[1]]
#merge with original
  dim(delta)
  dim(delta2020)
  delta<-Reduce(function(...) { merge(...,all.x=TRUE) }, list(delta,delta2020[,c(ids,"E2020")]))
  dim(delta)
  delta$Edelta<-delta$Employment_rv-delta$E2020
  delta$Edelta<-ifelse(delta$Year<=2020,0,delta$Edelta)
#  summary(subset(delta,Year==2017))


#do the same for all shocks
for (i in 2:length(shocks))
{
  pivot<-subset(data1,investment.shock==shocks[i])
  pivot2020<-subset(pivot,Year==2020)
  pivot2020$E2020<-pivot2020[,vars[1]]
 #merge with original
   dim(pivot)
   dim(pivot2020)
   pivot<-Reduce(function(...) { merge(...,all.x=TRUE) }, list(pivot,pivot2020[,c(ids,"E2020")]))
   dim(pivot)
   pivot$Edelta<-pivot$Employment_rv-pivot$E2020
   pivot$Edelta<-ifelse(pivot$Year<=2020,0,pivot$Edelta)
   delta<-rbind(delta,pivot)
}

#append run id
  delta$Run.idNew<-delta$Run.id


#now add this delta to the original gender mix
#read the data that needs to be appended:
 data2<-read.csv("C:\\Users\\Usuario\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-01-25\\investment_result_all\\data on june 18\\meso_report_2021_06_18_hm.csv")

#original
  #              "scenario 0-updated" "scenario 0"         "sp18"                      "sp30"               "sp30_updated"

#
#0
 e0<-subset(delta,investment.shock=="scenario 0")
 d0<-subset(data2,investment.shock=="scenario 0")
 dim(d0)
 dim(e0)
 d0<-Reduce(function(...) { merge(...) }, list(d0,e0[,c("Sector","Scenario","Year","covid.shock","calib.run","shock.type","Edelta","Run.idNew")]))
 dim(d0)
 d0$Employment_rv<-d0$Employment_rv+0#d0$Edelta
 d0$investment.shock<-unique(e0$investment.shock)
 d0$Edelta<-NULL
 d0$Run.id<-d0$Run.idNew
 d0$Run.idNew<-NULL

#1
 e1<-subset(delta,investment.shock=="ndpnet")
 d1<-subset(data2,investment.shock=="scenario 0")
 dim(d1)
 dim(e1)
 d1<-Reduce(function(...) { merge(...) }, list(d1,e1[,c("Sector","Scenario","Year","covid.shock","calib.run","shock.type","Edelta","Run.idNew")]))
 dim(d1)
 d1$Employment_rv<-d1$Employment_rv+d1$Edelta
 d1$investment.shock<-unique(e1$investment.shock)
 d1$Edelta<-NULL
 d1$Run.id<-d1$Run.idNew
 d1$Run.idNew<-NULL

#2
 e2<-subset(delta,investment.shock=="sp18")
 d2<-subset(data2,investment.shock=="scenario 0")
 dim(d2)
 dim(e2)
 d2<-Reduce(function(...) { merge(...) }, list(d2,e2[,c("Sector","Scenario","Year","covid.shock","calib.run","shock.type","Edelta","Run.idNew")]))
 dim(d2)
 d2$Employment_rv<-d2$Employment_rv+d2$Edelta
 d2$investment.shock<-unique(e2$investment.shock)
 d2$Edelta<-NULL
 d2$Run.id<-d2$Run.idNew
 d2$Run.idNew<-NULL

#3
 e3<-subset(delta,investment.shock=="sp30")
 d3<-subset(data2,investment.shock=="scenario 0")
 dim(d3)
 dim(e3)
 d3<-Reduce(function(...) { merge(...) }, list(d3,e3[,c("Sector","Scenario","Year","covid.shock","calib.run","shock.type","Edelta","Run.idNew")]))
 dim(d3)
 d3$Employment_rv<-d3$Employment_rv+d3$Edelta
 d3$investment.shock<-unique(e3$investment.shock)
 d3$Edelta<-NULL
 d3$Run.id<-d3$Run.idNew
 d3$Run.idNew<-NULL

 #updated
 #0
  u0<-subset(delta,investment.shock=="scenario 0-updated")
  du0<-subset(data2,investment.shock=="scenario 0-updated")
  dim(du0)
  dim(u0)
  du0<-Reduce(function(...) { merge(...) }, list(du0,u0[,c("Sector","Scenario","Year","covid.shock","calib.run","shock.type","Edelta","Run.idNew")]))
  dim(du0)
  du0$Employment_rv<-du0$Employment_rv+0#du0$Edelta
  du0$investment.shock<-unique(u0$investment.shock)
  du0$Edelta<-NULL
  du0$Run.id<-du0$Run.idNew
  du0$Run.idNew<-NULL
#

 #1
  u1<-subset(delta,investment.shock=="ndpnet_updated")
  du1<-subset(data2,investment.shock=="scenario 0-updated")
  dim(du1)
  dim(u1)
  du1<-Reduce(function(...) { merge(...) }, list(du1,u1[,c("Sector","Scenario","Year","covid.shock","calib.run","shock.type","Edelta","Run.idNew")]))
  dim(du1)
  du1$Employment_rv<-du1$Employment_rv+du1$Edelta
  du1$investment.shock<-unique(u1$investment.shock)
  du1$Edelta<-NULL
  du1$Run.id<-du1$Run.idNew
  du1$Run.idNew<-NULL
#
#2
 u2<-subset(delta,investment.shock=="sp18_updated")
 du2<-subset(data2,investment.shock=="scenario 0-updated")
 dim(du2)
 dim(u2)
 du2<-Reduce(function(...) { merge(...) }, list(du2,u2[,c("Sector","Scenario","Year","covid.shock","calib.run","shock.type","Edelta","Run.idNew")]))
 dim(du2)
 du2$Employment_rv<-du2$Employment_rv+du2$Edelta
 du2$investment.shock<-unique(u2$investment.shock)
 du2$Edelta<-NULL
 du2$Run.id<-du2$Run.idNew
 du2$Run.idNew<-NULL
#
#3
 u3<-subset(delta,investment.shock=="sp30_updated")
 du3<-subset(data2,investment.shock=="scenario 0-updated")
 dim(du3)
 dim(u3)
 du3<-Reduce(function(...) { merge(...) }, list(du3,u3[,c("Sector","Scenario","Year","covid.shock","calib.run","shock.type","Edelta","Run.idNew")]))
 dim(du3)
 du3$Employment_rv<-du3$Employment_rv+du3$Edelta
 du3$investment.shock<-unique(u3$investment.shock)
 du3$Edelta<-NULL
 du3$Run.id<-du3$Run.idNew
 du3$Run.idNew<-NULL

#rbind
 final<-rbind(d0,d1,d2,d3,du0,du1,du2,du3)
 final$gender_mix<-"50-50"
 #final$id<-with(final,paste(calib.run,covid.shock,investment.shock,Scenario,shock.type,sep="_"))
 #unique(unique(data2$id)%in%unique(final$id))
 final$id<-with(final,paste(calib.run,covid.shock,investment.shock,Scenario,shock.type,gender_mix,sep="_"))

 write.csv(final,"meso_report_experiment.csv",row.names=FALSE)

#read final file and aggregate it
 data3<-read.csv("C:\\Users\\Usuario\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-01-25\\investment_result_all\\data on june 22_EqualityFocus_experiment\\meso_report_2021_06_22_hm.csv")
vars<-c("Employment_gr",
        "exports_gr",
        "houselholds.cosumption_gr",
        "imports_gr",
        "value.added_gr",
        "Employment_rv",
        "exports_rv",
        "houselholds.cosumption_rv",
        "imports_rv",
        "value.added_rv",
        #
        "Employment_gr.B",
                "exports_gr.B",
                "houselholds.cosumption_gr.B",
                "imports_gr.B",
                "value.added_gr.B",
                "Employment_rv.B",
                "exports_rv.B",
                "houselholds.cosumption_rv.B",
                "imports_rv.B",
                "value.added_rv.B")

fagg<-aggregate(data3[,vars],list(Scenario= data3$Scenario,
                           Year= data3$Year,
                           covid.shock= data3$covid.shock,
                           investment.shock= data3$investment.shock,
                           calib.run= data3$calib.run,
                           shock.type= data3$shock.type,
                           Run.id=  data3$Run.id,
                          # Sector_en = data3$Sector_en ,
                           Sector_Calib=data3$Sector_Calib,
                           id=data3$id,
                           gender_mix=data3$gender_mix),sum)

write.csv(fagg,"Aggregatedmeso_report_2021_06_22_hm.csv",row.names=FALSE)













#process first original
#reference
 e0<-subset(data1,investment.shock=="scenario 0")
 e0<-e0[,c(ids,vars)]
 colnames(e0)[8]<-"Employment_rvS0"
 e0$investment.shock<-NULL

#rest
#e1
 e1<-subset(data1,investment.shock=="ndpnet")
#merge with epivot
 dim(e1)
 dim(e0)
 e1<-Reduce(function(...) { merge(...) }, list(e1,e0))
 dim(e1)
 e1$Edelta<-e1$Employment_rv-e1$Employment_rvS0
 e1$Run.idNew<-e1$Run.id
#
#e2
 e2<-subset(data1,investment.shock=="sp18")
#merge with epivot
 dim(e2)
 dim(e0)
 e2<-Reduce(function(...) { merge(...) }, list(e2,e0))
 dim(e2)
 e2$Edelta<-e2$Employment_rv-e2$Employment_rvS0
 e2$Run.idNew<-e2$Run.id
#
#e3
 e3<-subset(data1,investment.shock=="sp30")
#merge with epivot
 dim(e3)
 dim(e0)
 e3<-Reduce(function(...) { merge(...) }, list(e3,e0))
 dim(e3)
 e3$Edelta<-e3$Employment_rv-e3$Employment_rvS0
 e3$Run.idNew<-e3$Run.id

 #process updated
 #reference
  u0<-subset(data1,investment.shock=="scenario 0-updated")
  u0<-u0[,c(ids,vars)]
  colnames(u0)[8]<-"Employment_rvS0"
  u0$investment.shock<-NULL
#
#u1
 u1<-subset(data1,investment.shock=="ndpnet_updated")
#merge with epivot
 dim(u1)
 dim(u0)
 u1<-Reduce(function(...) { merge(...) }, list(u1,u0))
 dim(u1)
 u1$Edelta<-u1$Employment_rv-u1$Employment_rvS0
 u1$Run.idNew<-u1$Run.id
#
#u2
 u2<-subset(data1,investment.shock=="sp18_updated")
#merge with epivot
 dim(u2)
 dim(u0)
 u2<-Reduce(function(...) { merge(...) }, list(u2,u0))
 dim(u2)
 u2$Edelta<-u2$Employment_rv-u2$Employment_rvS0
 u2$Run.idNew<-u2$Run.id
#
#u3
 u3<-subset(data1,investment.shock=="sp30_updated")
#merge with epivot
 dim(u3)
 dim(u0)
 u3<-Reduce(function(...) { merge(...) }, list(u3,u0))
 dim(u3)
 u3$Edelta<-u3$Employment_rv-u3$Employment_rvS0
 u3$Run.idNew<-u3$Run.id
#delta set
 e0<-e1
 e0$investment.shock<-"scenario 0"
 e0$Edelta<-0
 u0<-u1
 u0$investment.shock<-"scenario 0-updated"
 u0$Edelta<-0
 delta<-rbind(e0,e1,e2,e3,u0,u1,u2,u3)

#read the data that needs to be appended:
 data2<-read.csv("C:\\Users\\Usuario\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-01-25\\investment_result_all\\data on june 18\\meso_report_2021_06_18_hm.csv")

#original
#1
 d1<-subset(data2,investment.shock=="scenario 0")
 dim(d1)
 dim(e1)
 d1<-Reduce(function(...) { merge(...) }, list(d1,e1[,c("Sector","Scenario","Year","covid.shock","calib.run","shock.type","Edelta","Run.idNew")]))
 dim(d1)
 d1$Employment_rv<-d1$Employment_rv+d1$Edelta
 d1$investment.shock<-unique(e1$investment.shock)
 d1$Edelta<-NULL
 d1$Run.id<-d1$Run.idNew
 d1$Run.idNew<-NULL

#2
 d2<-subset(data2,investment.shock=="scenario 0")
 dim(d2)
 dim(e2)
 d2<-Reduce(function(...) { merge(...) }, list(d2,e2[,c("Sector","Scenario","Year","covid.shock","calib.run","shock.type","Edelta","Run.idNew")]))
 dim(d2)
 d2$Employment_rv<-d2$Employment_rv+d2$Edelta
 d2$investment.shock<-unique(e2$investment.shock)
 d2$Edelta<-NULL
 d2$Run.id<-d2$Run.idNew
 d2$Run.idNew<-NULL

#3
 d3<-subset(data2,investment.shock=="scenario 0")
 dim(d3)
 dim(e3)
 d3<-Reduce(function(...) { merge(...) }, list(d3,e3[,c("Sector","Scenario","Year","covid.shock","calib.run","shock.type","Edelta","Run.idNew")]))
 dim(d3)
 d3$Employment_rv<-d3$Employment_rv+d3$Edelta
 d3$investment.shock<-unique(e3$investment.shock)
 d3$Edelta<-NULL
 d3$Run.id<-d3$Run.idNew
 d3$Run.idNew<-NULL

 #updated
 #1
  du1<-subset(data2,investment.shock=="scenario 0-updated")
  dim(du1)
  dim(u1)
  du1<-Reduce(function(...) { merge(...) }, list(du1,u1[,c("Sector","Scenario","Year","covid.shock","calib.run","shock.type","Edelta","Run.idNew")]))
  dim(du1)
  du1$Employment_rv<-du1$Employment_rv+du1$Edelta
  du1$investment.shock<-unique(u1$investment.shock)
  du1$Edelta<-NULL
  du1$Run.id<-du1$Run.idNew
  du1$Run.idNew<-NULL
#
#2
 du2<-subset(data2,investment.shock=="scenario 0-updated")
 dim(du2)
 dim(u2)
 du2<-Reduce(function(...) { merge(...) }, list(du2,u2[,c("Sector","Scenario","Year","covid.shock","calib.run","shock.type","Edelta","Run.idNew")]))
 dim(du2)
 du2$Employment_rv<-du2$Employment_rv+du2$Edelta
 du2$investment.shock<-unique(u2$investment.shock)
 du2$Edelta<-NULL
 du2$Run.id<-du2$Run.idNew
 du2$Run.idNew<-NULL
#
#3
 du3<-subset(data2,investment.shock=="scenario 0-updated")
 dim(du3)
 dim(u3)
 du3<-Reduce(function(...) { merge(...) }, list(du3,u3[,c("Sector","Scenario","Year","covid.shock","calib.run","shock.type","Edelta","Run.idNew")]))
 dim(du3)
 du3$Employment_rv<-du3$Employment_rv+du3$Edelta
 du3$investment.shock<-unique(u3$investment.shock)
 du3$Edelta<-NULL
 du3$Run.id<-du3$Run.idNew
 du3$Run.idNew<-NULL

#add base data sets
  d0<-subset(data2,investment.shock=="scenario 0")
  du0<-subset(data2,investment.shock=="scenario 0-updated")

#rbind
 final<-rbind(d0,d1,d2,d3,du0,du1,du2,du3)
 final$gender_mix<-"50-50"
 final$id<-with(final,paste(calib.run,covid.shock,investment.shock,Scenario,shock.type,gender_mix,sep="_"))
 write.csv(final,"meso_report_experiment.csv",row.names=FALSE)












summary()



c2<-subset(data,Sector=="total" & Run.id==1)








list(Scenario Year covid.shock   investment.shock calib.run shock.type Run.id),sum)



#for checks
summary(subset(data,Sector=="domest"))
summary(subset(data,Sector=="taxis"))
summary(subset(data,Sector=="admpub"))
summary(subset(data,Sector=="lw-female"))
summary(subset(data,Sector=="total"))


#we nneed to add Scenario investment yr 1 and base scenario

#keep only the part that you want
