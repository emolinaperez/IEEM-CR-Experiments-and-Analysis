#create experimental design
#so I want to sample over 39*2 paramter combinations
#first define the exploration ranges for each parameters
#the first set of 39 parameters is related related to the labour shock
#the second set of 39 parameters is related to excess capacity
#the third set of 3 parameters is related to wage unemployment elasiticies

#read ieem restrictions input file

#subset to specific design
 rts<-read.csv("C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-01-25\\user-files\\cri2016rand\\IEEM_experiment_inputs_new.csv")
 rts<-subset(rts,Design=='401-800_new')

#order bounds according to ieem input files

 ieem.combo<-read.csv("C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-01-25\\user-files\\cri2016rand\\IEEM_to_aggregate_sector_new.csv")
 dim(ieem.combo)
 ieem.combo$id  <- 1:nrow(rts)
 ieem.combo<-merge(ieem.combo,rts,by="IEEM.Combo",all.x=TRUE)
 dim(ieem.combo)
 ieem.combo<-ieem.combo[order(ieem.combo$id), ]

#create vectors
 labor.shocks.min<-ieem.combo[1:39,"Min"]
 labor.shocks.max<-ieem.combo[1:39,"Max"]
 excap.shocks.min<-ieem.combo[40:78,"Min"]
 excap.shocks.max<-ieem.combo[40:78,"Max"]
 wage.shocks.min<-ieem.combo[79:81,"Min"]
 wage.shocks.max<-ieem.combo[79:81,"Max"]

labor.shocks<-
              matrix(c(
                       #inferior limits
                         labor.shocks.min,
                        #rep(0.7,39),
                        #rep(0.85,39),
                        #c(0.90,0.93,0.90,0.86,0.88,0.85,1.03,0.89,0.95,0.85,0.95,0.97,0.98,0.91,0.98,0.92,0.98,0.92,1.05,0.89,0.89,0.87,0.94,0.98,0.86,0.99,0.89,0.99,0.92,0.96,0.88,0.89,0.88,0.93,0.92,1.04,0.91,0.86,0.96),
                       #superior limits
                        labor.shocks.max
                        #rep(1.5,39)
                        #rep(1.15,39)
                        #c(1.03,0.96,0.99,1.07,0.96,1.04,1.05,1.04,0.97,1.02,1.09,0.98,1.12,1.10,0.99,1.15,1.04,0.93,1.08,1.03,1.14,1.09,0.95,1.04,0.95,1.10,0.90,1.08,1.05,0.97,1.13,1.06,0.93,0.93,1.01,1.05,0.93,0.95,0.99)
                      ),
                      ncol=2
                      )
#
exc.shocks<-
              matrix(c(
                       #inferior limits
                         excap.shocks.min,
                        # rep(-.10,39),
                        #rep(-.10,39),
                        #c(-0.09,-0.07,-0.08,-0.08,-0.09,-0.05,-0.08,-0.08,-0.07,-0.09,-0.09,-0.08,-0.05,-0.09,-0.07,-0.08,-0.09,-0.05,-0.09,-0.09,-0.07,-0.05,-0.09,-0.05,-0.06,-0.07,-0.09,-0.06,-0.05,-0.09,-0.09,-0.06,-0.05,-0.08,-0.08,-0.04,-0.06,-0.04,-0.09),
                       #superior limits
                        excap.shocks.max
                        # rep(-0.03,39)
                        #rep(-0.03,39)
                        #c(-0.03,-0.04,-0.07,-0.07,-0.06,-0.04,-0.07,-0.05,-0.05,-0.08,-0.05,-0.06,-0.05,-0.09,-0.06,-0.07,-0.05,-0.03,-0.07,-0.07,-0.06,-0.03,-0.04,-0.03,-0.04,-0.03,-0.03,-0.05,-0.04,-0.07,-0.07,-0.04,-0.03,-0.07,-0.03,-0.03,-0.04,-0.03,-0.03)
                      ),
                      ncol=2
                      )
#
wage.el<- matrix(c(
                     #inferior limits
                        wage.shocks.min,
                       #rep(-1.0,3),
                       #c(-0.3,-0.4,-0.7),
                       #c(-0.22,-0.31,-0.69),
                     #superior limits
                        wage.shocks.max
                       #rep(-0.05,3)
                      #c(-0.05,-0.05,-0.05)
                       #c(-0.06,-0.06,-0.06)
                  ),
                  ncol=2
                 )

Domains<-rbind(labor.shocks,exc.shocks,wage.el)

#Now define the sample size
 library(lhs)
 set.seed(5000)
 sample.size<-400
 lhs.sample<-data.frame(randomLHS(sample.size, nrow(Domains)))

for (j in 1:nrow(Domains))
{
  lhs.sample[,j]<-qunif(lhs.sample[,j],Domains[j,1],Domains[j,2])
}

#now the print the experidemental design
 lhs.sample$Run.id<-c(1:nrow(lhs.sample))

#write output file
 write.csv(lhs.sample,"C:\\Users\\L03054557\\OneDrive\\Edmundo-ITESM\\3.Proyectos\\30. Costa Rica COVID19\\IEEM-en-GAMS-with-EXCAP-2021-01-25\\user-files\\cri2016rand\\exp_design_2021_04_14.csv",row.names=FALSE)
