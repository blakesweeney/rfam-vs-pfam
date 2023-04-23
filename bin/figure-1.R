#!/usr/bin/env Rscript

library(tidyverse)
library(ggridges)
library(ggpubr)

args <- commandArgs(trailingOnly = TRUE)
data <- read_csv(args[1], locale = locale(decimal_mark = ","))
counts <- read_tsv(args[2])
output <- args[3]

data$Puzzle <- fct_reorder(data$Puzzle, data$Index)
data[data$RMSD > 40, ]$RMSD <- 40

labels <- data %>%
    group_by(Year) %>%
    summarise(ymin = min(Index), ymax = max(Index), ymid = mean(Index)) %>%
    rename(label = Year)

counts <- counts %>%
    group_by(Puzzle) %>%
    summarise(
        Puzzle = Puzzle,
        Length = sum(Length))

pivoted <- data %>%
    pivot_longer(!Index & !Puzzle & !Year & !Category, names_to = "Metric") %>%
    mutate(Metric = ifelse(Metric == "RMSD", "RMSD (Å)", Metric)) %>%
    filter(Metric %in% c("RMSD (Å)", "INF-NWC", "INF-WC")) %>%
    inner_join(counts, by = c("Puzzle")) %>%
    mutate(Puzzle = str_c(str_pad(Puzzle, 6, "right"), "(", Length, ")"))

pivoted$Puzzle <- fct_reorder(pivoted$Puzzle, pivoted$Index)

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
ggsave(file.path(output, "figure-1.png"), plot, device = "png", dpi=600)
