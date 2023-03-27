#!/usr/bin/env Rscript

library(tidyverse)
library(ggbeeswarm)
library(ggridges)

plot_metric_box <- function(data, ymax, ymin=0) {
  yrange <- abs(ymax - ymin)
  labels <- data %>%
    group_by(Year) %>%
    summarise(x = mean(Index),
              y = ymax * (-9.5 / 80),
              yshift = ymax * (2 / 80),
              text = min(Year),
              xmin = min(Index),
              xmax = max(Index))

    plot <- ggplot(data, aes(x = Puzzle, y = value)) +
        geom_boxplot(aes(group = Puzzle)) +
        theme_classic() +
        theme(axis.text.x = element_text(angle = 45, vjust = 0.5),
              plot.margin = margin(l = 25, r = 10, t = 10, b = 25)) +
        geom_segment(data = labels,
                     mapping = aes(x = xmin - 0.2,
                                 xend = xmax + 0.2,
                                 y = y + yshift,
                                 yend = y + yshift)) +
        coord_cartesian(clip = "off", expand = FALSE, ylim = c(0, ymax)) +
        geom_text(data = labels, aes(x = x, y = y, label = text, hjust = 0.5)) +
        geom_smooth(aes(x = Index, y = value),
                    method = "lm",
                    col = "blue",
                    se = FALSE) +
        xlab("")

    return(plot)
}

plot_beeswarm <- function(data, ymax, ymin=0) {
  yrange <- abs(ymax - ymin)
  labels <- data %>%
    group_by(Year) %>%
    summarise(x = mean(Index),
              y = ymax * (-9.5 / 80),
              yshift = ymax * (2 / 80),
              text = min(Year),
              xmin = min(Index),
              xmax = max(Index))

    plot <- ggplot(data, aes(x = Puzzle, y = value)) +
        geom_quasirandom(aes(group = Puzzle)) +
        theme_classic() +
        theme(axis.text.x = element_text(angle = 45, vjust = 0.5),
              plot.margin = margin(l = 25, r = 10, t = 10, b = 25)) +
        geom_segment(data = labels,
                     mapping = aes(x = xmin - 0.2,
                                 xend = xmax + 0.2,
                                 y = y + yshift,
                                 yend = y + yshift)) +
        coord_cartesian(clip = "off", expand = FALSE, ylim = c(0, ymax)) +
        geom_text(data = labels, aes(x = x, y = y, label = text, hjust = 0.5)) +
        geom_smooth(aes(x = Index, y = value),
                    method = "lm",
                    col = "blue",
                    se = FALSE) +
        xlab("")

    return(plot)
}

plot_ridges <- function(data, ymax, ymin=0) {
    plot <- ggplot(data, aes(y = Puzzle, x = value)) +
        geom_density_ridges(aes(group = Puzzle)) +
        theme_classic() +
        xlim(ymin, ymax)

    return(plot)
}

plot_ridges_colored <- function(data, ymax, ymin=0) {
    d <- data %>% mutate(Year = factor(Year))
    plot <- ggplot(d, aes(y = Puzzle, x = value, group = Puzzle, fill = Year)) +
        geom_density_ridges() +
        theme_classic() +
        scale_fill_discrete() +
        xlim(ymin, ymax)

    return(plot)
}

plot_ridge_boxes_colored <- function(data, ymax, ymin=0) {
    d <- data %>% mutate(Year = factor(Year))
    plot <- ggplot(d, aes(y = Puzzle, x = value, group = Puzzle, fill = Year)) +
        geom_density_ridges(stat = "binline", bins = 50) +
        theme_classic() +
        scale_fill_discrete() +
        xlim(ymin, ymax)

    return(plot)
}

args <- commandArgs(trailingOnly = TRUE)
data <- read_csv(args[1], locale = locale(decimal_mark = ","))
output <- args[2]

data$Puzzle <- fct_reorder(data$Puzzle, data$Index)
pivoted <- data %>%
    pivot_longer(!Index & !Puzzle & !Year & !Category, names_to = "Metric")

medians <- data %>%
    group_by(Puzzle) %>%
    summarise(Index = min(Index),
              median_inf_all = median(`INF-all`),
              median_inf_wc = median(`INF-WC`),
              median_inf_nwc = median(`INF-NWC`),
              median_inf_stacking = median(`INF-stacking`),
              median_rmsd = median(RMSD))

################################################################3
# Merged plots
################################################################3

plot <- pivoted %>%
    filter(Metric %in% c("RMSD", "INF-NWC", "INF-WC")) %>%
    ggplot(aes(x = Index, y = value)) +
        geom_smooth(method = "lm", col = "blue", se = FALSE) +
        geom_boxplot(aes(group = Puzzle)) +
        facet_grid(Metric ~ ., scales="free") +
        ylab("Value") +
        theme_classic()
ggsave(file.path(output, "all-metrics-box-trend.png"), plot, device = "png")

plot <- pivoted %>%
    filter(Metric %in% c("INF-NWC", "INF-WC", "RMSD")) %>%
    mutate(Year = factor(Year)) %>%
    ggplot(aes(x = value, y = Puzzle, group = Puzzle, fill = Year)) +
    geom_density_ridges() +
    facet_grid(. ~ Metric, scales = "free") +
    theme_classic() +
    scale_fill_discrete() +
    xlab("")
ggsave(file.path(output, "all-metrics-ridges-colors.png"), plot, device = "png")

plot <- pivoted %>%
    filter(Metric %in% c("INF-NWC", "INF-WC", "RMSD")) %>%
    mutate(Year = factor(Year)) %>%
    ggplot(aes(x = value, y = Puzzle, group = Puzzle, fill = Year)) +
    geom_density_ridges(stat = "binline", bins = 50) +
    facet_grid(. ~ Metric, scales = "free") +
    theme_classic() +
    scale_fill_discrete() +
    xlab("")
ggsave(file.path(output, "all-metrics-box-ridges-colors.png"), plot, device = "png")

################################################################3
# RMSD
################################################################3

plot <- pivoted %>%
    filter(Metric %in% c("RMSD")) %>%
    plot_metric_box(ymax = 80) +
    ylab("RMSD (Å)")
ggsave(file.path(output, "rmsd-box-trend.png"), plot, device = "png")

plot <- pivoted %>%
    filter(Metric %in% c("RMSD")) %>%
    plot_beeswarm(ymax = 80) +
    ylab("RMSD (Å)")
ggsave(file.path(output, "rmsd-points-trend.png"), plot, device = "png")

plot <- pivoted %>%
    filter(Metric %in% c("RMSD")) %>%
    plot_ridges(ymax = 80) +
    xlab("RMSD (Å)")
ggsave(file.path(output, "rmsd-points-ridges.png"), plot, device = "png")

plot <- pivoted %>%
    filter(Metric %in% c("RMSD")) %>%
    plot_ridges_colored(ymax = 80) +
    xlab("RMSD (Å)")
ggsave(file.path(output, "rmsd-points-ridges-colors.png"), plot, device = "png")

plot <- pivoted %>%
    filter(Metric %in% c("RMSD")) %>%
    plot_ridge_boxes_colored(ymax = 80) +
    xlab("RMSD (Å)")
ggsave(file.path(output, "rmsd-points-ridge-boxes-colors.png"), plot, device = "png")

################################################################3
# INF-NWC
################################################################3

plot <- pivoted %>%
    filter(Metric == "INF-NWC") %>%
    plot_metric_box(ymax = 1) +
    ylab("non-Watson Crick Basepair Similarity")
ggsave(file.path(output, "inf-nwc-box-trend.png"), plot, device = "png")

plot <- pivoted %>%
    filter(Metric == "INF-NWC") %>%
    plot_beeswarm(ymax = 1) +
    ylab("non-Watson Crick Basepair Similarity")
ggsave(file.path(output, "inf-nwc-points-trend.png"), plot, device = "png")

plot <- pivoted %>%
    filter(Metric == "INF-NWC") %>%
    plot_ridges(ymax = 1) +
    xlab("non-Watson Crick Basepair Similarity")
ggsave(file.path(output, "inf-nwc-ridges.png"), plot, device = "png")

plot <- pivoted %>%
    filter(Metric == "INF-NWC") %>%
    plot_ridges_colored(ymax = 1) +
    xlab("non-Watson Crick Basepair Similarity")
ggsave(file.path(output, "inf-nwc-ridges-colors.png"), plot, device = "png")

plot <- pivoted %>%
    filter(Metric == "INF-NWC") %>%
    plot_ridge_boxes_colored(ymax = 1) +
    xlab("non-Watson Crick Basepair Similarity")
ggsave(file.path(output, "inf-nwc-ridge-boxes-colors.png"), plot, device = "png")

################################################################3
# INF-WC
################################################################3

plot <- pivoted %>%
    filter(Metric %in% c("INF-WC")) %>%
    plot_metric_box(ymax = 1) +
    ylab("Watson Crick Basepair Similarity")
ggsave(file.path(output, "inf-wc-box-trend.png"), plot, device = "png")

plot <- pivoted %>%
    filter(Metric %in% c("INF-WC")) %>%
    plot_beeswarm(ymax = 1) +
    ylab("Watson Crick Basepair Similarity")
ggsave(file.path(output, "inf-wc-points-trend.png"), plot, device = "png")

plot <- pivoted %>%
    filter(Metric %in% c("INF-WC")) %>%
    plot_ridges(ymax = 1) +
    xlab("Watson Crick Basepair Similarity")
ggsave(file.path(output, "inf-wc-ridges.png"), plot, device = "png")

plot <- pivoted %>%
    filter(Metric %in% c("INF-WC")) %>%
    plot_ridges_colored(ymax = 1) +
    xlab("Watson Crick Basepair Similarity")
ggsave(file.path(output, "inf-wc-ridges-colors.png"), plot, device = "png")

plot <- pivoted %>%
    filter(Metric %in% c("INF-WC")) %>%
    plot_ridge_boxes_colored(ymax = 1) +
    xlab("Watson Crick Basepair Similarity")
ggsave(file.path(output, "inf-wc-ridge-boxes-colors.png"), plot, device = "png")
