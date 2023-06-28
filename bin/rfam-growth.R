#!/usr/bin/env Rscript

library(tidyverse)
library(ggplot2)

args <- commandArgs(trailingOnly = TRUE)
data <- read_csv(args[1])
output <- args[2]

standard_theme <- theme_classic() +
    theme(axis.text = element_text(size = 12),
          axis.title = element_text(size = 14))

data$Date <- parse_date(data$Date, "%m/%y")

data

model <- lm(families ~ Date, data)
summary(model)

ggplot(data, aes(x = Date, y = families)) +
    geom_point() +
    geom_smooth(method = "lm", se = FALSE) +
    ylab("Number of Families") +
    xlab("Release Date") +
    standard_theme

ggsave(file.path(output, "rfam-growth.png"), device = "png", dpi = 600)
