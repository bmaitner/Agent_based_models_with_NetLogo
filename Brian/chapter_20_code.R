#Code for chapter 20

cal<-read.csv("Brian/Sect20-5_WoodHoopoes Calibration-table.csv",skip = 6)


#Calibration criteria

#only use november data
#ignore years 1 and 2

cal <- cal[which(cal$year > 2 & cal$month == 11),]

#Mean abundance is in the range 115-135
#Standard deviation from year to year in population size is 10 - 15
#Average percentage of territories that lack one or both alphas: 15-30%

#Need output table containing:
  #parm values
  #mean abundance
  #st dev in abundance
  #mean percent of territories that lack an alpha

output <- unique(cal[c("scout.prob","survival.prob")])
output$mean_abundance <- NA
output$sd_abundance <- NA
output$mean_pct_vacant_alphas <- NA

for( i in 1:nrow(output)){
  
  #output$scout.prob[i]
  #output$survival.prob[i]

  data_i <- cal[which(cal$scout.prob==  output$scout.prob[i]) & cal$survival.prob ==  output$survival.prob[i],]
  output$mean_abundance[i] <- mean(data_i$count.turtles)
  output$sd_abundance[i] <- sd(data_i$count.turtles)
  output$mean_pct_vacant_alphas[i] <- mean(data_i$count.patches.with..count..turtles.here.with..is.alpha......2./25*100)
  rm(i,data_i)  
  
}

#Mean abundance is in the range 115-135
plot(xlim=c(min(output$scout.prob),max(output$scout.prob)),
     ylim=c(min(output$survival.prob),max(output$survival.prob)),
     x = output$scout.prob[output$mean_abundance>=115 & output$mean_abundance<=135],
     y = output$survival.prob[output$mean_abundance>=115 & output$mean_abundance<=135],
     xlab = "p scout",ylab = "p survival")

#Standard deviation from year to year in population size is 10 - 15
points(x = output$scout.prob[output$sd_abundance>=10 & output$sd_abundance<=15],
       y = output$survival.prob[output$sd_abundance>=10 & output$sd_abundance<=15],pch=0)

#Average percentage of territories that lack one or both alphas: 15-30%

points(x = output$scout.prob[output$mean_pct_vacant_alphas>=15 & output$mean_pct_vacant_alphas<=30],
       y = output$survival.prob[output$mean_pct_vacant_alphas>=15 & output$mean_pct_vacant_alphas<=30],pch=3)

points(x = output$scout.prob,
       y = output$survival.prob,pch=20,cex=0.5)

