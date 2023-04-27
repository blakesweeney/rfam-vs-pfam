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
                   color = `Data Type`)) +
    geom_line() +
    geom_text(aes(x = xleft,
                  y = ycenter,
                  label = `Target Kind`,
                  group = `Target Kind`),
              hjust = "inward",
              data = labels,
              col = rgb(0, 0, 0)) +
    theme_classic() +
    scale_fill_grey(name = "") +
    scale_color_grey(name = "") +
    ylab("")

ggsave(file.path(output, "figure-2.png"), plot, device = "png", dpi=600)
