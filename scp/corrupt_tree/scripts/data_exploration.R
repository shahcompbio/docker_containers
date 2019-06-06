#!/usr/bin/env Rscript
require("ggplot2") 
require("dplyr")
require("optparse")

option_list <- list(make_option(c("-f", "--file"), type="character", default=NULL, help="straighten_jitter_output_csv", metavar="character"),
					make_option(c("-o", "--out"), type="character", default="out.pdf", help="output_file_name", metavar="character"))

opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

data <- read.csv(opt$file)
data_summary <- data %>%
    group_by(loci) %>%
    summarize(n_positive = sum(tipInclusionProbabilities))
p <- ggplot(data_summary, aes(x = reorder(loci, -n_positive), y = n_positive)) +
    geom_bar(stat = "identity") +
    theme_bw()

ggsave(opt$out, device="pdf", p)
