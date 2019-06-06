#!/usr/bin/env Rscript
require("ggplot2") 
require("dplyr")
require("stringr")
require("optparse")

option_list <- list(make_option(c("-f", "--file"), type="character", default=NULL, help="fpr_&_fnr_csv", metavar="character"),
					make_option(c("-t", "--trace"), type="character", default="trace.pdf", help="trace_output", metavar="character"),
					make_option(c("-b", "--box"), type="character", default="box.pdf", help="box_output", metavar="character")
				)
  
opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

data <- read.csv(opt$file)

p <- ggplot(data, aes(x = sample, y = value, colour = factor(entry))) +
    geom_line() +
    facet_grid(factor(entry) ~ .) +
    theme_bw() +
    theme(legend.position="none")
ggsave(opt$trace, plot = p, width = 5, height = 50, limitsize = FALSE, device="pdf")
  
p <- ggplot(data, aes(x = entry, y = value, colour = factor(entry))) +
    geom_boxplot(outlier.size = 0) + 
    theme_bw() +
    theme(legend.position="none")
ggsave(opt$box, plot = p, width = 20, height = 5, limitsize = FALSE, device="pdf")
