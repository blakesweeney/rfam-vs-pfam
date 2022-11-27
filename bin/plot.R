library(tidyr)

data <- read_csv("merged.csv")

light_rfam <- "#F7EFEC"
medium_rfam <- "#A8887B"
dark_rfam <- "#541D08"

light_pfam <- "#EEF5FC"
medium_pfam <- "#C7D4E6"
dark_pfam <- "#1D427E"

pivoted <- data %>% pivot_longer(!id & !description & !source & !rna_type, names_to="stat", values_to="value")

# Some general stats
ggplot(pivoted, aes(x=source, y=value, colour=source, fill=source)) +
	facet_grid(rows=vars(stat), scales="free_y") +
	geom_violin() +
	scale_y_log10() +
	scale_color_manual(values = c("#BECBDC", "#A18276")) +
	scale_fill_manual(values = c("#BECBDC", "#A18276"))


# Rfam families cover a very few types of RNAs
rna_type_df <- data %>%
	filter(source == 'Rfam seed') %>%
	select(id, rna_type) %>%
	group_by(rna_type) %>%
	summarise(count=n())
rna_type_df$fraction = rna_type_df$count / sum(rna_type_df$count)

## Displayed by counts
ggplot(rna_type_df, aes(x=reorder(rna_type, -count), y=count)) +
	geom_bar(stat="identity") +
	theme(axis.text.x = element_text(angle = 45, vjust=0.9, hjust=1)) +
	labs(x="Rfam RNA type", y="Count of families")

## Displayed by percent
ggplot(rna_type_df, aes(x=reorder(rna_type, -count), y=fraction)) +
	geom_bar(stat="identity") +
	theme(axis.text.x = element_text(angle = 45, vjust=0.9, hjust=1)) +
	labs(x="Rfam RNA type", y="Fraction of families") +
	 scale_y_continuous(limits=c(0, 0.4), labels=scales::percent)



# Can expand this to more data for separate plots
library(gridExtra)
library(grid)
number_seqs <- pivoted %>% filter(stat == "number_seqs")
number_residues <- pivoted %>% filter(stat == "number_residues")

number_seqs_p <- ggplot(number_seqs, aes(x=source, y=value, color=source, fill=source)) +
	geom_violin() +
	scale_y_log10() +
	scale_color_manual(values = c("#BECBDC", "#A18276")) +
	scale_fill_manual(values = c("#BECBDC", "#A18276")) +
	labs(y="Number of sequences")
number_residues_p <- ggplot(number_residues, aes(x=source, y=value, color=source, fill=source)) +
	geom_violin() +
	scale_y_log10() +
	scale_color_manual(values = c("#BECBDC", "#A18276")) +
	scale_fill_manual(values = c("#BECBDC", "#A18276")) +
	labs(y="Number of residues")

 grid.arrange(number_residues_p, number_seqs_p, ncol=1)
