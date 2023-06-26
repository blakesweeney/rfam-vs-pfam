#!/usr/bin/env Rscript

library(tidyverse)

args <- commandArgs(trailingOnly = TRUE)
data <- read_csv(args[1])
output <- args[2]

by_year <- data %>%
  group_by(`Year`, `Target Kind`) %>%
  summarise(`Number of Groups` = sum(`Number of Groups`),
            predictions = sum(`Number of Predictions`),
            `Number of Targets` = sum(`Number of targets`))

without_predictions <- by_year %>%
    pivot_longer(cols = c(`Number of Groups`, predictions, `Number of Targets`)) %>%
    filter(name != "predictions") %>%
    rename(`Data Type` = name)

labels <- without_predictions %>%
    group_by(`Target Kind`) %>%
    filter(Year == min(Year)) %>%
    summarise(ymin = min(value),
              ymax = max(value),
              ycenter = median(value),
              xleft = min(Year) + 0.5)

plot <- ggplot(without_predictions,
               aes(x = Year,
                   y = value,
                   group = interaction(`Target Kind`, `Data Type`),
    )) +
    geom_path(aes(linetype = `Data Type`)) +
    geom_text(aes(x = xleft,
                  y = ycenter,
                  label = `Target Kind`,
                  group = `Target Kind`),
              hjust = "inward",
              data = labels,
              size = 7,
              col = rgb(0, 0, 0)) +
    theme_classic() +
    scale_color_grey(name = "", guide = guide_legend(title = "")) +
    ylab("Number of Groups and Targets") +
    theme(axis.text = element_text(size = 14),
          axis.title = element_text(size = 16),
          legend.position = c(0.20, 0.1),
          legend.title = element_blank(),
          legend.text = element_text(size = 14))

ggsave(file.path(output, "figure-3.png"), plot, device = "png", dpi = 600)
