#!/usr/bin/env Rscript

library(tidyverse)

rna_color <- rgb(80, 29, 9, maxColorValue = 255)
protein_color <- rgb(26, 64, 122, maxColorValue = 255)

args <- commandArgs(trailingOnly = TRUE)
data <- read_csv(args[1])
output <- args[2]

no_dna <- data %>% filter(Molecule != "DNA")

data <- data %>%
    group_by(Year) %>%
    mutate(yearly_total = sum(`Number of structures`),
           `Fraction of yearly structures` = `Number of structures` / yearly_total * 100)

no_dna <- no_dna %>%
    group_by(Year) %>%
    mutate(yearly_no_dna = sum(`Number of structures`),
           no_dna_fraction = `Number of structures` / yearly_no_dna * 100)

plot <- ggplot(data,
    aes(x = Year,
        y = `Number of structures`,
        group = Molecule,
        col = Molecule,
        fill = Molecule)) +
    geom_bar(stat = "identity") +
    theme_classic() +
    scale_y_log10()
ggsave(file.path(output, "pdb-log-number-structures.png"), plot, device = "png")

plot <- ggplot(no_dna,
               aes(x = Year,
                   y = `Number of structures`,
                   group = Molecule,
                   col = Molecule,
                   fill = Molecule)) +
    geom_bar(stat = "identity") +
    scale_y_log10() +
    theme_classic() +
    scale_fill_manual(guide = guide_legend(title = "Molecule"),
                      values = c(protein_color, rna_color)) +
    scale_color_manual(values = c(protein_color, rna_color))
ggsave(file.path(output, "pdb-log-number-structures-no-dna.png"),
       plot,
       device = "png")

plot <- ggplot(no_dna,
               aes(x = Year,
                   y = `Number of structures`,
                   group = Molecule,
                   col = Molecule,
                   fill = Molecule)) +
    geom_bar(stat = "identity") +
    theme_classic() +
    scale_fill_manual(guide = guide_legend(title = "Molecule"),
                      values = c(protein_color, rna_color)) +
    scale_color_manual(values = c(protein_color, rna_color))
ggsave(file.path(output, "pdb-number-structures-no-dna.png"),
       plot,
       device = "png")

plot <- ggplot(no_dna,
               aes(x = Year,
                   y = `Number of structures`,
                   group = Molecule,
                   col = Molecule,
                   fill = Molecule,
                   label = `Number of structures`)) +
    geom_bar(stat = "identity") +
    geom_text(size = 3, position = position_stack(vjust = 0.5), col = "white") +
    theme_classic() +
    lab("A") +
    scale_fill_manual(guide = guide_legend(title = "Molecule"),
                      values = c(protein_color, rna_color)) +
    scale_color_manual(values = c(protein_color, rna_color))
ggsave(file.path(output, "pdb-number-structures-no-dna-labeled.png"),
       plot,
       device = "png")

plot <- ggplot(no_dna,
               aes(x = Year,
                   y = `Number of structures`,
                   group = Molecule,
                   col = Molecule,
                   fill = Molecule,
                   label = `Number of structures`)) +
    geom_bar(stat = "identity") +
    geom_text(size = 3, position = position_stack(vjust = 0.5), col = "white") +
    theme_classic() +
    lab("A") +
    scale_y_log10() +
    scale_fill_manual(guide = guide_legend(title = "Molecule"),
                      values = c(protein_color, rna_color)) +
    scale_color_manual(values = c(protein_color, rna_color))
ggsave(file.path(output, "pdb-log-number-structures-no-dna-labeled.png"),
       plot,
       device = "png")

plot <- ggplot(data,
               aes(x = Year,
                   y = `Fraction of yearly structures`,
                   group = Molecule,
                   fill = Molecule)) +
    theme_classic() +
    geom_bar(stat = "identity")
ggsave(file.path(output, "pdb-fraction_structures.png"),
       plot,
       device = "png")
