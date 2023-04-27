#!/usr/bin/env Rscript

library(tidyverse)

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

rfam_summary_df <- data %>%
    left_join(structures, by = "rfam_acc") %>%
    mutate(rna_type = factor(rna_type),
           number_of_structures = replace_na(number_of_structures, 0)) %>%
    filter(startsWith(source, "Rfam")) %>%
    select(rfam_acc,
           rna_type,
           number_seqs,
           number_of_structures,
           source) %>%
    group_by(rna_type) %>%
    summarise(
      Families = n_distinct(rfam_acc),
      "Seed Sequences" = sum(number_seqs[source == "Rfam seed"]),
      "Full Sequences" = sum(number_seqs[source == "Rfam full"]),
      "Structures" = sum(number_of_structures)) %>%
    mutate(rna_type = fct_reorder(rna_type, Families, min, .desc = TRUE))

rfam_structures_df <- rfam_summary_df %>%
    pivot_longer(!rna_type, names_to = "stat") %>%
    mutate(stat = factor(stat,
           levels = c("Families", "Seed Sequences", "Full Sequences", "Structures")))

plot <- ggplot(rfam_structures_df,
               aes(x = rna_type, y = value)) +
    geom_bar(stat = "identity") +
    facet_grid(stat ~ ., scales = "free_y", switch="both") +
    theme_classic() +
    theme(axis.text.x = element_text(angle = 45, vjust = 0.9, hjust = 1)) +
    theme(
      strip.background = element_blank(),
      strip.placement = "outside"
    ) +
    labs(x = "", y = "")

ggsave(file.path(output, "figure-4.png"), plot, device = "png", dpi = 600)
