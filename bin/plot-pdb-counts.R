#!/usr/bin/env Rscript

library(tidyverse)
library(scales)
library(viridis)

args <- commandArgs(trailingOnly = TRUE)
data <- read_csv(args[1])
output <- args[2]

data$Resolution <- factor(data$Resolution,
                          levels = c("≤2.0Å", ">2.0Å ≤3.0Å", ">3.0Å"))

plot <- ggplot(data,
               aes(x = Molecule,
                   y = `Number of structures`,
                   group = `Resolution`,
                   fill = Resolution)) +
    geom_col(position = "dodge") +
    scale_y_log10(label = comma) +
    geom_text(aes(label = comma(`Number of structures`)),
                  position = position_dodge(1),
                  vjust = 0) +
    scale_fill_viridis(discrete = TRUE, direction = -1) +
    ylab("Number of Structures")
ggsave(file.path(output, "structures-by-resolution-kind.png"),
       plot,
       device = "png")
