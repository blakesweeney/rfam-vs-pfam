#!/usr/bin/env Rscript

library(tidyverse)
library(ggpubr)
library(scales)

light_rfam <- rgb(80, 29, 9, alpha = 255 * 0.5, maxColorValue = 255)
rna_color <- rgb(80, 29, 9, maxColorValue = 255)
protein_color <- rgb(26, 64, 122, maxColorValue = 255)
light_pfam <- rgb(26, 64, 122, alpha = 255 * 0.5, maxColorValue = 255)

colors <- c(light_pfam, protein_color, light_rfam, rna_color)

args <- commandArgs(trailingOnly = TRUE)
data <- read_csv(args[1])
rfam_structures <- read_csv(args[2])
output <- args[3]

data$alignment_size <- data$number_of_columns * data$number_seqs
data$number_of_gaps <- data$alignment_size - data$number_residues
data$fraction_gap <- data$number_of_gaps / data$alignment_size * 100

standard_theme <- theme_classic() +
    theme(axis.text = element_text(size = 12),
          axis.title.y = element_text(size = 14))

pivoted <- data %>%
    pivot_longer(!rfam_acc & !description & !source & !rna_type,
                 names_to = "stat",
                 values_to = "value")

medians <- data %>%
    group_by(source) %>%
    summarise(
        median_cols = median(number_of_columns),
        median_seqs = median(number_seqs),
        median_identity = median(percent_identity),
        median_gaps = median(fraction_gap))

structures <- rfam_structures %>%
    filter(is_significant == 1) %>%
    group_by(rfam_acc) %>%
    summarise(number_of_structures = n())

rna_type_df <- data %>%
        filter(startsWith(source, "Rfam")) %>%
        select(rfam_acc, rna_type, number_seqs) %>%
        group_by(rna_type) %>%
        summarise(
          count = n(),
          number_of_sequences = sum(number_seqs),
        )
rna_type_df$fraction <- rna_type_df$count / sum(rna_type_df$count)

data_summary <- function(x) {
   m <- median(x)
   ymin <- m-sd(x)
   ymax <- m+sd(x)
   return(c(y=m,ymin=ymin,ymax=ymax))
}

rfam_rna_type_df <- data %>%
    filter(startsWith(source, "Rfam")) %>%
    select(rfam_acc, rna_type, number_seqs) %>%
    group_by(rna_type) %>%
    summarise(
      count = n(),
      "Number of sequences" = sum(number_seqs),
    ) %>%
    mutate(rna_type = fct_reorder(rna_type, count, .desc = TRUE)) %>%
    rename("Number of families" = count) %>%
    pivot_longer(!rna_type, names_to = "stat")

plot1 <- ggplot(data,
               aes(x = source,
                   y = number_seqs)) +
    geom_violin(fill = "grey80") +
    stat_summary(fun.data = data_summary,
                 geom = "pointrange",
                 color = "black") +
    geom_text(data = medians,
              show.legend = FALSE,
              inherit.aes = FALSE,
              col = "black",
              aes(x = source,
                  y = median_seqs,
                  label = median_seqs),
              hjust = "left",
              nudge_x = 0.05,
) +
    scale_y_log10(label = comma) +
    standard_theme +
    labs(y = "Number of sequences", x = "", tag = "A")

plot2 <- ggplot(data,
               aes(x = source,
                   y = number_of_columns)) +
    geom_violin(fill = "grey80", trim = FALSE) +
    stat_summary(fun.data = data_summary,
                 geom = "pointrange",
                 color = "black") +
    geom_text(data = medians,
              show.legend = FALSE,
              inherit.aes = FALSE,
              col = "black",
              aes(x = source,
                  y = median_cols,
                  label = median_cols),
              hjust = "left",
              nudge_x = 0.08) +
    scale_y_log10(label = comma) +
    standard_theme +
    labs(y = "Number of columns", x = "", tag = "B")

plot3 <- ggplot(data,
               aes(x = source,
                   y = percent_identity)) +
    geom_violin(fill = "grey80") +
    stat_summary(fun.data = data_summary,
                 geom = "pointrange",
                 color = "black") +
    geom_text(data = medians,
              show.legend = FALSE,
              inherit.aes = FALSE,
              col = "black",
              aes(x = source,
                  y = median_identity,
                  label = median_identity),
              hjust = "left",
              nudge_x = 0.1) +
    scale_y_continuous(label = comma, limits = c(0, 100)) +
    standard_theme +
    labs(y = "Percent identity", x = "", tag = "C")

ggarrange(plot1, plot2, plot3, ncol = 1, nrow = 3, legend = "bottom", common.legend = TRUE)
ggsave(file.path(output, "figure-5.png"), device = "png", dpi = 600)
