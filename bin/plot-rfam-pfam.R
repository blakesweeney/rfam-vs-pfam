#!/usr/bin/env Rscript

library(tidyverse)

light_rfam <- "#F7EFEC"
medium_rfam <- "#A8887B"
dark_rfam <- "#541D08"

light_pfam <- "#EEF5FC"
medium_pfam <- "#C7D4E6"
dark_pfam <- "#1D427E"

colors <- c(light_pfam, medium_pfam, light_rfam, medium_rfam)

args <- commandArgs(trailingOnly = TRUE)
data <- read_csv(args[1])
structures <- read_csv(args[2])
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

# Some general stats
# ggplot(pivoted, aes(x=source, y=value, colour=source, fill=source)) +
#       facet_grid(rows=vars(stat), scales="free_y") +
#       geom_violin() +
#       scale_y_log10() +
#       scale_color_manual(values = c("#BECBDC", "#A18276")) +
#       scale_fill_manual(values = c("#BECBDC", "#A18276"))


# Rfam families cover a very few types of RNAs
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
      "Number of sequences"=sum(number_seqs),
    ) %>%
    mutate(rna_type=fct_reorder(rna_type, count, .desc=TRUE)) %>%
    rename("Number of families"=count) %>%
    pivot_longer(!rna_type, names_to = "stat")

## Displayed by counts
plot <- rfam_rna_type_df %>%
    filter(stat == "Number of families") %>%
    ggplot(aes(x = reorder(rna_type, -value), y = value)) +
    geom_bar(stat = "identity") +
    facet_grid(stat ~ ., scales = "free_y") +
    theme_classic() +
    theme(axis.text.x = element_text(angle = 45, vjust = 0.9, hjust = 1)) +
    labs(x = "RNA type", y = "Count")

ggsave(file.path(output, "family_counts.png"), plot = plot, device = "png")

## Alignment length
plot <- ggplot(data,
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
                  aes(x = source,
                      y = median_cols,
                      label = median_cols,
                      vjust = 1.5)) +
        scale_color_manual(values = colors) +
        scale_fill_manual(values = colors) +
    theme_classic() +
        labs(y = "Number of columns")

ggsave(file.path(output, "alignment_size.png"), plot, device = "png")

## Number of sequences
plot <- ggplot(data,
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
                  aes(x = source,
                      y = median_seqs,
                      label = median_seqs,
                      hjust = 0.5,
                      vjust = -0.5)) +
        scale_color_manual(values = colors) +
        scale_fill_manual(values = colors) +
    theme_classic() +
        labs(y = "Number of sequences")

ggsave(file.path(output, "alignment_length.png"), plot, device = "png")

## Percent identity
plot <- ggplot(data,
               aes(x = source,
                   y = percent_identity,
                   color = source,
                   fill = source)) +
        geom_violin() +
        geom_boxplot(width = 0.2, color = "black") +
        geom_text(data = medians,
                  show.legend = FALSE,
                  inherit.aes = FALSE,
                  aes(x = source,
                      y = median_identity,
                      label = median_identity,
                      vjust = -0.5)) +
        scale_color_manual(values = colors) +
        scale_fill_manual(values = colors) +
        scale_y_continuous(limits = c(0, 100)) +
    theme_classic() +
        labs(y = "Percent identity")

ggsave(file.path(output, "alignment_identity.png"), plot, device="png")

# Fraction of gaps
plot <- ggplot(data,
               aes(x = source,
                   y = fraction_gap,
                   color = source,
                   fill = source)) +
        geom_violin() +
        geom_boxplot(width = 0.2, color = "black") +
        geom_text(data = medians,
                  show.legend = FALSE,
                  inherit.aes = FALSE,
                  aes(x = source,
                      y = median_gaps,
                      label = median_gaps,
                      vjust = -0.5)) +
        scale_color_manual(values = colors) +
        scale_fill_manual(values = colors) +
    theme_classic() +
        labs(y = "Percent of gaps")

ggsave(file.path(output, "alignment_gaps.png"), alignment_gaps, device = "png")

# Displayed by percent
# ggplot(rna_type_df, aes(x=reorder(rna_type, -count), y=fraction)) +
#       geom_bar(stat="identity") +
#       theme(axis.text.x = element_text(angle = 45, vjust=0.9, hjust=1)) +
#       labs(x="Rfam RNA type", y="Fraction of families") +
#        scale_y_continuous(limits=c(0, 0.4), labels=scales::percent)

# # Can expand this to more data for separate plots
# library(gridExtra)
# library(grid)
# number_seqs <- pivoted %>% filter(stat == "number_seqs")
# number_residues <- pivoted %>% filter(stat == "number_residues")
#
# number_seqs_p <- ggplot(number_seqs, aes(x=source, y=value, color=source, fill=source)) +
#       geom_violin() +
#       scale_y_log10() +
#       scale_color_manual(values = c("#BECBDC", "#A18276")) +
#       scale_fill_manual(values = c("#BECBDC", "#A18276")) +
#       labs(y="Number of sequences")
# number_residues_p <- ggplot(number_residues, aes(x=source, y=value, color=source, fill=source)) +
#       geom_violin() +
#       scale_y_log10() +
#       scale_color_manual(values = c("#BECBDC", "#A18276")) +
#       scale_fill_manual(values = c("#BECBDC", "#A18276")) +
#       labs(y="Number of residues")
#
#  grid.arrange(number_residues_p, number_seqs_p, ncol=1)

rfam_structures_df <- data %>%
    left_join(structures, by = "rfam_acc") %>%
    mutate(rna_type = factor(rna_type)) %>%
    mutate(number_of_structures = replace_na(number_of_structures, 0)) %>%
        filter(startsWith(source, "Rfam")) %>%
        select(rfam_acc,
               rna_type,
               number_seqs,
               number_of_structures,
               source) %>%
        group_by(rna_type) %>%
        summarise(
          Families = n(),
          "Seed Sequences" = sum(number_seqs[source == "Rfam seed"]),
          "Full Sequences" = sum(number_seqs[source == "Rfam full"]),
          "Structures" = sum(number_of_structures)) %>%
    mutate(rna_type = fct_reorder(rna_type, Families, min, .desc = TRUE)) %>%
    pivot_longer(!rna_type, names_to = "stat")

plot <- ggplot(rfam_structures_df,
               aes(x = reorder(rna_type, -value), y = value)) +
        geom_bar(stat = "identity") +
        facet_grid(stat ~ ., scales = "free_y") +
    theme_classic() +
        theme(axis.text.x = element_text(angle = 45, vjust = 0.9, hjust = 1)) +
        labs(x = "Rfam RNA Type", y = "Count")

ggsave(file.path(output, "rfam_structures.png"), plot, device = "png")
