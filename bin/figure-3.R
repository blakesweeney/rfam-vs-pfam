#!/usr/bin/env Rscript

library(tidyverse)
library(ggpubr)

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
                   y = number_seqs,
                   color = source,
                   fill = source)) +
    geom_violin() +
    scale_y_log10() +
    geom_boxplot(width = 0.2, color = "black") +
    geom_text(data = medians,
              show.legend = FALSE,
              inherit.aes = FALSE,
              col = "white",
              aes(x = source,
                  y = median_seqs,
                  label = median_seqs,
                  hjust = 0.5,
                  vjust = -0.5)) +
    scale_color_manual(values = colors) +
    scale_fill_manual(values = colors) +
    theme_classic() +
    labs(y = "Number of sequences", x = "", tag = "A")

plot2 <- ggplot(data,
               aes(x = source,
                   y = number_of_columns,
                   color = source,
                   fill = source)) +
    geom_violin() +
    scale_y_log10() +
    geom_boxplot(width = 0.2, color = "black") +
    geom_text(data = medians,
              show.legend = FALSE,
              inherit.aes = FALSE,
              col = "white",
              aes(x = source,
                  y = median_cols,
                  label = median_cols,
                  vjust = -0.5)) +
    scale_color_manual(values = colors) +
    scale_fill_manual(values = colors) +
    theme_classic() +
    labs(y = "Number of columns", x = "", tag = "B")

plot3 <- ggplot(data,
               aes(x = source,
                   y = percent_identity,
                   color = source,
                   fill = source)) +
    geom_violin() +
    geom_boxplot(width = 0.2, color = "black") +
    geom_text(data = medians,
              show.legend = FALSE,
              inherit.aes = FALSE,
              col = "white",
              aes(x = source,
                  y = median_identity,
                  label = median_identity,
                  vjust = -0.5)) +
    scale_color_manual(values = colors) +
    scale_fill_manual(values = colors) +
    scale_y_continuous(limits = c(0, 100)) +
    theme_classic() +
    labs(y = "Percent identity", x = "", tag = "C")

ggarrange(plot1, plot2, plot3, ncol = 1, nrow = 3, legend = "bottom", common.legend = TRUE)
ggsave(file.path(output, "figure-3.png"), device = "png", dpi = 600)
