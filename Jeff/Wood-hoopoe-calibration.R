# Look at Wood Hoopoe calibration results
# Jeffrey C. Oliver
# jcoliver@email.arizona.edu
# 2019-04-22

rm(list = ls())

################################################################################
library(tidyverse)
wood.hoopoe <- read.csv(file = "Jeff/Sect20-5_WoodHoopoes Calibration-table.csv",
                        skip = 7)
# [run number]
# scout-prob
# survival-prob
# [step]
# year
# month
# count
# turtles
# count patches with [count (turtles-here with [is-alpha?]) < 2]
colnames(wood.hoopoe) <- c("run.num", "scout.prob", "surv.prob",
                           "step", "year", "month", "num.turtles",
                           "missing.alpha")

#' 3 Criteria
#' Mean abundance 115-135
#' SD from year to year population size is 10 - 15
#' Average % territories sans one or two alphas 15-30%

wood.hoopoe.qc <- wood.hoopoe[wood.hoopoe$year > 3 & 
                                wood.hoopoe$month == 11, ]

# Calculate mean abundance & % territories with 1 or 0 alphas
abundance <- wood.hoopoe.qc %>%
  group_by(surv.prob, scout.prob) %>%
  summarise(mean.abundance = mean(num.turtles),
            sd.abundance = sd(num.turtles),
            missing.alphas = mean(missing.alpha)/25)

# Plot mean abundance 
ggplot(data = abundance, mapping = aes(x = surv.prob, y = mean.abundance, color = scout.prob)) +
  geom_point() + 
  geom_hline(yintercept = c(115, 135), size = 0.2, color = "red")

# Plot standard deviation
ggplot(data = abundance, mapping = aes(x = surv.prob, y = sd.abundance, color = scout.prob)) +
  geom_point() + 
  geom_hline(yintercept = c(10, 15), size = 0.2, color = "red")


# Plot % plots missing at least one alpha
ggplot(data = abundance, mapping = aes(x = surv.prob, y = missing.alphas, color = scout.prob)) +
  geom_point() + 
  geom_hline(yintercept = c(0.15, 0.3), size = 0.2, color = "red")

# Subset the abundance data to those two criteria
abundance.critera.met <- abundance[abundance$mean.abundance >= 115 &
                                     abundance$mean.abundance <= 135 &
                                     abundance$sd.abundance >= 10 &
                                     abundance$sd.abundance <= 15 &
                                     abundance$missing.alphas >= 0.15 &
                                     abundance$missing.alphas <= 0.3, ]
