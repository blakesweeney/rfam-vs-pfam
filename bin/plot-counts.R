#!/usr/bin/env Rscript

library(tidyverse)

rna_color <- rgb(80, 29, 9, maxColorValue = 255)
protein_color <- rgb(26, 64, 122, maxColorValue = 255)

args <- commandArgs(trailingOnly = TRUE)
data <- read_csv(args[1])
output <- args[2]

by_year <- data %>%
  group_by(`Year`, `Target Kind`) %>%
  summarise(groups = sum(`Number of Groups`),
            predictions = sum(`Number of Predictions`),
            targets = sum(`Number of targets`))

# Makes it easy to compare RNA to protein
groups <- ggplot(by_year,
                 aes(x = Year,
                     y = groups,
                     group = `Target Kind`,
                     col = `Target Kind`)) +
  geom_line() +
  theme_classic() +
  scale_colour_manual(guide = guide_legend(title = "Molecule"),
                      values = c(protein_color, rna_color)) +
  ylab("Number of Groups")
ggsave(file.path(output, "number-of-groups.png"), groups, device = "png")

targets <- ggplot(by_year,
                  aes(x = Year,
                      y = targets,
                      group = `Target Kind`,
                      col = `Target Kind`)) +
  theme_classic() +
  scale_colour_manual(guide = guide_legend(title = "Molecule"),
                      values = c(protein_color, rna_color)) +
  geom_line() +
  ylab("Number of Targets")
ggsave(file.path(output, "number-of-targets.png"), targets, device = "png")

predictions <- ggplot(by_year,
                      aes(x = Year,
                          y = predictions,
                          group = `Target Kind`,
                          col = `Target Kind`)) +
  theme_classic() +
  scale_colour_manual(guide = guide_legend(title = "Molecule"),
                      values = c(protein_color, rna_color)) +
  geom_line() +
  ylab("Number of Predictions")
ggsave(file.path(output, "number-of-predictions.png"),
       predictions,
       device = "png")

# Easy way to compare changes over time for each resource
pivoted <- by_year %>% pivot_longer(cols = c(groups, predictions, targets))

# Put everything on one plot
all_counts <- ggplot(pivoted,
                     aes(x = Year,
                         y = value,
                         group = interaction(`Target Kind`, name),
                         shape = name,
                         color = `Target Kind`)) +
  geom_line() +
  geom_point() +
  theme_classic() +
  scale_colour_manual(guide = guide_legend(title = "Molecule"),
                      values = c(protein_color, rna_color)) +
  ylab("") +
  scale_y_log10()
ggsave(file.path(output, "all-counts.png"), all_counts, device = "png")

without_predictions <- pivoted %>% filter(name != "predictions")
all_no_pred_counts <- ggplot(without_predictions,
                             aes(x = Year,
                                 y = value,
                                 group = interaction(`Target Kind`, name),
                                 shape = name,
                                 color = `Target Kind`)) +
  geom_line() +
  geom_point() +
  theme_classic() +
  scale_colour_manual(guide = guide_legend(title = "Molecule"),
                      values = c(protein_color, rna_color)) +
  ylab("")
ggsave(file.path(output, "all-counts-no-predictions.png"),
       all_no_pred_counts, device = "png")

all_no_pred_counts <- ggplot(without_predictions,
                     aes(x = Year,
                         y = value,
                         group = interaction(`Target Kind`, name),
                         shape = `Target Kind`,
                         color = name)) +
  geom_line() +
  geom_point() +
  theme_classic() +
  ylab("")
ggsave(file.path(output, "all-counts-no-predictions-swap-sym-colors.png"),
       all_no_pred_counts, device = "png")

labels <- without_predictions %>%
    filter(Year == max(without_predictions$Year)) %>%
    group_by(`Target Kind`) %>%
    summarise(ymin = min(value),
              ymax = max(value),
              ycenter = median(value),
              xleft = max(Year))

plot <- ggplot(without_predictions,
               aes(x = Year,
                   y = value,
                   group = interaction(`Target Kind`, name),
                   color = name)) +
  geom_line() +
  geom_text(aes(x = xleft,
                y = ycenter,
                label = `Target Kind`,
                group = `Target Kind`),
            data = labels,
            col = rgb(0, 0, 0)) +
  theme_classic() +
  ylab("")
ggsave(file.path(output, "all-counts-no-predictions-labels.png"),
       plot, device = "png")

# ggplot(pivoted, aes(x=Year, y=value, group=name, col=name)) + geom_line() + facet_grid(rows=vars(`Target Kind`), scales="free") + scale_y_log10()
# One plot with two facets, I don't think it is as nice as either separate or
# combined plots.

# TODO: Produce a bar plot where each bar is colored by source, to show that
#       CASP is now predicting RNA
