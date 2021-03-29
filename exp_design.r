#create experimental design
#so I want to sample over 39*2 paramter combinations
#first define the exploration ranges for each parameters
#the first 39 parameters are related to the labour shock
#the second 39 parameters are related to excess capacity

labor.shocks<-
              matrix(c(
                       #inferior limits
                        rep(0.85,39),
                       #superior limits
                        rep(1.05,39)
                      ),
                      ncol=2
                      )
#
exc.shocks<-
              matrix(c(
                       #inferior limits
                        rep(-.10,39),
                       #superior limits
                        rep(-0.03,39)
                      ),
                      ncol=2
                      )
#
Domains<-rbind(labor.shocks,exc.shocks)

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
