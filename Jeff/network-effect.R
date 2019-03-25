# Looking at investor model results
# Jeffrey C. Oliver
# jcoliver@email.arizona.edu
# 2019-03-25

rm(list = ls())

################################################################################
network.data <- read.csv(file = "Jeff/Business-investor network-size-effect-table.csv",
                         skip = 7)
colnames(network.data) <- c("run", "links", "turtles",
                            "radius", "step", "wealth")
library(ggplot2)
network.plot <- ggplot(data = network.data, 
                       mapping = aes(x = links, y = wealth, color = radius)) +
  geom_point()
print(network.plot)

network.plot <- ggplot(data = network.data, 
                       mapping = aes(x = radius, y = wealth, color = links)) +
  geom_point()
print(network.plot)
