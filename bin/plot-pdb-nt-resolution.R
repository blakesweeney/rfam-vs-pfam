#!/usr/bin/env Rscript

library(tidyverse)
library(viridis)

args <- commandArgs(trailingOnly = TRUE)
data <- read_csv(args[1], locale = readr::locale(encoding = "UTF-8"))
output <- args[2]

data$Year <- factor(data$Year)
data$Molecule <- factor(data$Molecule)
data$Resolution <- factor(data$Resolution,
    levels = c("≤2.0Å", ">2.0Å ≤3.0Å", ">3.0Å ≤5.0Å", ">5.0Å"))

data <- data %>%
    group_by(Year, Molecule) %>%
    mutate(yearly_total = sum(`Number of residues`),
           fraction = `Number of residues` / yearly_total)

no_dna <- data %>% filter(Molecule != "DNA")

plot <- ggplot(data,
       aes(x = Molecule,
           group = Resolution,
           y = `Number of residues`,
           fill = Resolution)) +
    geom_bar(stat = "identity") +
    theme_classic() +
    scale_color_viridis(discrete = TRUE, direction = -1) +
    scale_fill_viridis(discrete = TRUE, direction = -1) +
    facet_grid(~ Year, switch = "both")
ggsave(file.path(output, "resolution-total-counts.png"), plot, device = "png")

plot <- ggplot(no_dna,
       aes(x = Molecule,
           group = Resolution,
           y = fraction,
           fill = Resolution)) +
    geom_bar(stat = "identity") +
    theme_classic() +
    scale_color_viridis(discrete = TRUE, direction = -1) +
    scale_fill_viridis(discrete = TRUE, direction = -1) +
    facet_grid(~ Year, switch = "both") +
    ylab("Fraction of total structures")
ggsave(file.path(output, "resolution-fraction-no-dna.png"),
       plot,
       device = "png")

plot <- ggplot(data,
       aes(x = Molecule,
           group = Resolution,
           y = fraction,
           fill = Resolution)) +
    geom_bar(stat = "identity") +
    theme_classic() +
    scale_color_viridis(discrete = TRUE, direction = -1) +
    scale_fill_viridis(discrete = TRUE, direction = -1) +
    facet_grid(~ Year, switch = "both") +
    ylab("Fraction of total structures")
ggsave(file.path(output, "resolution-fraction.png"), plot, device = "png")
