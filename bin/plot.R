#!/usr/bin/env Rscript

library(tidyverse)

args = commandArgs(trailingOnly=TRUE)
structures <- read_csv(args[2])

data <- read_csv(args[1])

light_rfam <- "#F7EFEC"
medium_rfam <- "#A8887B"
dark_rfam <- "#541D08"

light_pfam <- "#EEF5FC"
medium_pfam <- "#C7D4E6"
dark_pfam <- "#1D427E"

data$alignment_size <- data$number_of_columns * data$number_seqs
data$number_of_gaps <- data$alignment_size - data$number_residues
data$fraction_gap <- data$number_of_gaps / data$alignment_size * 100

pivoted <- data %>% pivot_longer(!rfam_acc & !id & !description & !source & !rna_type, names_to="stat", values_to="value")
medians <- data %>% 
    group_by(source) %>% 
    summarise(
	median_cols=median(number_of_columns),
	median_seqs=median(number_seqs),
	median_identity=median(percent_identity),
	median_gaps=median(fraction_gap))

# Some general stats
# ggplot(pivoted, aes(x=source, y=value, colour=source, fill=source)) +
#	facet_grid(rows=vars(stat), scales="free_y") +
#	geom_violin() +
#	scale_y_log10() +
#	scale_color_manual(values = c("#BECBDC", "#A18276")) +
#	scale_fill_manual(values = c("#BECBDC", "#A18276"))


# Rfam families cover a very few types of RNAs
rna_type_df <- data %>%
	filter(source == 'Rfam seed') %>%
	select(id, rna_type, number_seqs) %>%
	group_by(rna_type) %>%
	summarise(
	  count=n(),
	  number_of_sequences=sum(number_seqs),
	)
rna_type_df$fraction = rna_type_df$count / sum(rna_type_df$count)

rna_type_df <- data %>%
    filter(source == 'Rfam seed') %>%
    select(id, rna_type, number_seqs) %>%
    group_by(rna_type) %>%
    summarise(
	count=n(),
	"Number of seed sequences"=sum(number_seqs),
    ) %>%
    mutate(rna_type=fct_reorder(rna_type, count, .desc=TRUE)) %>%
    rename("Number of families"=count) %>%
    pivot_longer(!rna_type, names_to="stat")

with_structures <- data %>% 
    left_join(structures, by="rfam_acc") %>% 
    mutate(number_of_structures=replace_na(number_of_structures, 0))

## Displayed by counts
family_counts <- rna_type_df %>%
    filter(stat == "Number of families") %>%
    ggplot(aes(x=reorder(rna_type, -value), y=value)) +
    geom_bar(stat="identity") + facet_grid(stat ~ ., scales="free_y") +
    theme(axis.text.x = element_text(angle = 45, vjust=0.9, hjust=1)) +
    labs(x="RNA type", y="Count")

ggsave("family_counts.png", plot=family_counts, device="png")

## Alignment length
alignment_size <- ggplot(data, aes(x=source, y=number_of_columns, color=source, fill=source)) +
	geom_violin() +
	scale_y_log10() +
	geom_boxplot(width=0.2, color="black") +
	geom_text(data=medians,
		  show.legend=FALSE,
		  inherit.aes=FALSE,
		  aes(x=source, y=median_cols, label=median_cols, vjust=1.5) ) +
	scale_color_manual(values = c(medium_pfam, medium_rfam)) +
	scale_fill_manual(values = c(medium_pfam, medium_rfam)) +
	labs(y="Number of columns")

ggsave("alignment_size.png", alignment_size, device="png")

## Number of sequences
alignment_length <- ggplot(data, aes(x=source, y=number_seqs, color=source, fill=source)) +
	geom_violin() +
	scale_y_log10() +
	geom_boxplot(width=0.2, color="black") +
	geom_text(data=medians,
		  show.legend=FALSE,
		  inherit.aes=FALSE,
		  aes(x=source, y=median_seqs, label=median_seqs, hjust=0.5, vjust=-0.5) ) +
	scale_color_manual(values = c(medium_pfam, medium_rfam)) +
	scale_fill_manual(values = c(medium_pfam, medium_rfam)) +
	labs(y="Number of sequences")

ggsave("alignment_length.png", alignment_length, device="png")

## Percent identity
alignment_identity <- ggplot(data, aes(x=source, y=percent_identity, color=source, fill=source)) +
	geom_violin() +
	geom_boxplot(width=0.2, color="black") +
	geom_text(data=medians,
		  show.legend=FALSE,
		  inherit.aes=FALSE,
		  aes(x=source, y=median_identity, label=median_identity, vjust=-0.5) ) +
	scale_color_manual(values = c(medium_pfam, medium_rfam)) +
	scale_fill_manual(values = c(medium_pfam, medium_rfam)) +
	scale_y_continuous(limits=c(0, 100)) +
	labs(y="Percent identity")

ggsave("alignment_identity.png", alignment_identity, device="png")

# Fraction of gaps
alignment_gaps <- ggplot(data, aes(x=source, y=fraction_gap, color=source, fill=source)) +
	geom_violin() +
	geom_boxplot(width=0.2, color="black") +
	geom_text(data=medians,
		  show.legend=FALSE,
		  inherit.aes=FALSE,
		  aes(x=source, y=median_gaps, label=median_gaps, vjust=-0.5) ) +
	scale_color_manual(values = c(medium_pfam, medium_rfam)) +
	scale_fill_manual(values = c(medium_pfam, medium_rfam)) +
	labs(y="Percent of gaps")

ggsave("alignment_gaps.png", alignment_gaps, device="png")

# Displayed by percent
# ggplot(rna_type_df, aes(x=reorder(rna_type, -count), y=fraction)) +
#	geom_bar(stat="identity") +
#	theme(axis.text.x = element_text(angle = 45, vjust=0.9, hjust=1)) +
#	labs(x="Rfam RNA type", y="Fraction of families") +
#	 scale_y_continuous(limits=c(0, 0.4), labels=scales::percent)

# # Can expand this to more data for separate plots
# library(gridExtra)
# library(grid)
# number_seqs <- pivoted %>% filter(stat == "number_seqs")
# number_residues <- pivoted %>% filter(stat == "number_residues")
#
# number_seqs_p <- ggplot(number_seqs, aes(x=source, y=value, color=source, fill=source)) +
#	geom_violin() +
#	scale_y_log10() +
#	scale_color_manual(values = c("#BECBDC", "#A18276")) +
#	scale_fill_manual(values = c("#BECBDC", "#A18276")) +
#	labs(y="Number of sequences")
# number_residues_p <- ggplot(number_residues, aes(x=source, y=value, color=source, fill=source)) +
#	geom_violin() +
#	scale_y_log10() +
#	scale_color_manual(values = c("#BECBDC", "#A18276")) +
#	scale_fill_manual(values = c("#BECBDC", "#A18276")) +
#	labs(y="Number of residues")
#
#  grid.arrange(number_residues_p, number_seqs_p, ncol=1)

rna_type_df2 <- with_structures %>%
  	filter(source == 'Rfam seed') %>%
  	select(id, rna_type, number_seqs, number_of_structures) %>%
  	group_by(rna_type) %>%
  	summarise(
  	  families=n(),
  	  seed=sum(number_seqs),
  	  structures=sum(number_of_structures)) %>% 
	mutate(rna_type=factor(rna_type)) %>%
	mutate(rna_type=reorder(rna_type, -families)) %>%
	pivot_longer(!rna_type, names_to="stat")

 structures_plot <- ggplot(rna_type_df2, aes(x=reorder(rna_type, -value), y=value)) +
  	geom_bar(stat="identity") + facet_grid(stat ~ ., scales="free_y") +
  	theme(axis.text.x = element_text(angle = 45, vjust=0.9, hjust=1)) + labs(x="RNA type", y="Count")

ggsave("rfam_structures.png", structures_plot, device="png")
