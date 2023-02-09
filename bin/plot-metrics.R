#!/usr/bin/env Rscript

library(tidyverse)

plot_metric_range <- function(data, ymax, ymin=0) {
  labels <- data %>%
    group_by(Year) %>%
    summarise(x = median(Index),
              y = ymax * (-9.5 / 80),
              yshift = ymax * (2 / 80),
              text = min(Year),
              xmin = min(Index),
              xmax = max(Index))

  plot <- ggplot(data, aes(x = Index)) +
    geom_ribbon(aes(x = Index, ymin = Min, ymax = Max), fill = "grey70") +
    geom_line(aes(x = Index, y = Min)) +
    geom_line(aes(x = Index, y = Max)) +
    scale_x_continuous(labels  =  data$Puzzle, breaks  =  data$Index) +
    theme_classic() +
    theme(axis.text.x = element_text(angle = 45, vjust = 0.5)) +
    annotate(geom = "text", x = labels$x, y = labels$y, label = labels$text) +
    coord_cartesian(ylim  =  c(ymin, ymax), expand  =  FALSE, clip  =  "off")  +
    annotate("segment",
             x = labels$xmin - 0.2,
             xend = labels$xmax + 0.2,
             y = labels$y + labels$yshift,
             yend = labels$y + labels$yshift) +
    xlab("Puzzle") +
    theme(axis.title.x = element_text(margin = margin(t = 40)),
          plot.margin = margin(l = 25, r = 10, t = 10))
  return(plot)
}

args <- commandArgs(trailingOnly=TRUE)
data <- read_csv(args[1])
output <- args[2]

rmsd_plot <- data %>%
  filter(Metric == "RMSD") %>%
  plot_metric_range(ymax=80) +
    ylab("RMSD (Å)")
ggsave(file.path(output, "rmsd.png"), rmsd_plot, device="png")

inf_all_plot <- data %>%
  filter(Metric == "INF (all)") %>%
  plot_metric_range(ymax=1) +
    ylab("Interaction Similarity")
ggsave(file.path(output, "inf-all.png"), inf_all_plot, device="png")

non_wc_plot <- data %>%
  filter(Metric == "INF-NWC") %>%
  plot_metric_range(ymax=1) +
    ylab("Non-Watson Crick Base Pair Similarity")
ggsave(file.path(output, "inf-ncw.png"), non_wc_plot, device="png")

wc_plot <- data %>%
  filter(Metric == "INF-WC") %>%
  plot_metric_range(ymax=1) +
    ylab("Watson Crick Base Pair Similarity")
ggsave(file.path(output, "inf-cw.png"), wc_plot, device="png")

stacking_plot <- data %>%
  filter(Metric == "INF-stacking") %>%
  plot_metric_range(ymax=1) +
    ylab("Stacking Similarity")
ggsave(file.path(output, "inf-stacking.png"), stacking_plot, device="png")

# all_plots <- plot_metric_range(data) +
#     facet_grid(Metric ~ ., scales = "free") +
#     ylab("")
# ggsave(file.path(output, "all-metrics.png"), all_plots, device="png")
