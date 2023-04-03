#!/usr/bin/env Rscript

library(tidyverse)
library(ggbeeswarm)
library(ggridges)
library(ggpubr)

args <- commandArgs(trailingOnly = TRUE)
data <- read_csv(args[1], locale = locale(decimal_mark = ","))
output <- args[2]

data$Puzzle <- fct_reorder(data$Puzzle, data$Index)
data[data$RMSD > 40, ]$RMSD <- 40
pivoted <- data %>%
    pivot_longer(!Index & !Puzzle & !Year & !Category, names_to = "Metric") %>%
    mutate(Metric = ifelse(Metric == "RMSD", "RMSD (Å)", Metric)) %>%
    filter(Metric %in% c("RMSD (Å)", "INF-NWC", "INF-WC"))

plot <- ggplot(pivoted, aes(x = value, y = Puzzle, group = Puzzle)) +
    geom_density_ridges(stat = "binline", bins = 50, alpha = 0.7) +
    facet_wrap(. ~ Metric, scales = "free_x", strip.position = "bottom") +
    theme_classic() +
    theme(
      strip.background = element_blank(),
      strip.placement = "outside"
    ) +
    xlab("") +
    scale_x_continuous(labels = function(x) ifelse(x == 40, "≥40", x))
ggsave(file.path(output, "figure-1.png"), plot, device = "png")
