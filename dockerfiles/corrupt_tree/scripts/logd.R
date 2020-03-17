#!/usr/bin/env Rscript
require("ggplot2") 
require("dplyr")
require("optparse")

option_list <- list(make_option(c("-f", "--file"), type="character", default=NULL, help="log_density_csv", metavar="character"), 
                    make_option(c("-o", "--out"), type="character", default="out.pdf", help="output_file_name", metavar="character"))
  
opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

data <- read.csv(opt$file)

p <- ggplot(data, aes(x = sample, y = value)) +
    geom_line() +
    theme_bw()
#ggsave( "trace-logDensity.pdf", width = 5, height = 5, limitsize = FALSE, device="pdf")
ggsave(opt$out, width = 5, height = 5, limitsize = FALSE, device="pdf")
