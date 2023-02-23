library(tidyverse)
library(viridis)

args <- commandArgs(trailingOnly = TRUE)
data <- read_csv(args[1])
output <- args[2]

data$Year <- factor(data$Year)
data$Molecule <- factor(data$Molecule)
data$Resolution <- factor(data$Resolution)

data <- data %>%
    group_by(Year, Molecule) %>%
    mutate(yearly_total = sum(`Number of residues`),
           fraction = `Number of residues` / yearly_total)

no_dna <- data %>% filter(Molecule != "DNA")

plot <- ggplot(data,
       aes(x = Molecule,
           group = Resolution,
           y = `Number of residues`,
           fill = Resolution)) +
    geom_bar(stat = "identity") +
    scale_color_viridis(discrete = TRUE) +
    scale_fill_viridis(discrete = TRUE) +
    facet_grid(~ Year)
ggsave(file.path(output, "resolution-total-counts.png"), plot, device = "png")

plot <- ggplot(no_dna,
       aes(x = Molecule,
           group = Resolution,
           y = fraction,
           fill = Resolution)) +
    geom_bar(stat = "identity") +
    scale_color_viridis(discrete = TRUE) +
    scale_fill_viridis(discrete = TRUE) +
    facet_grid(~ Year) +
    ylab("Fraction of total structures")
ggsave(file.path(output, "resolution-fraction-no-dna.png"),
       plot,
       device = "png")

plot <- ggplot(dna,
       aes(x = Molecule,
           group = Resolution,
           y = fraction,
           fill = Resolution)) +
    geom_bar(stat = "identity") +
    scale_color_viridis(discrete = TRUE) +
    scale_fill_viridis(discrete = TRUE) +
    facet_grid(~ Year) +
    ylab("Fraction of total structures")
ggsave(file.path(output, "resolution-fraction.png"), plot, device = "png")
