#!/usr/bin/env Rscript

require("dplyr")
require("tidyr")
require("reshape2")
require("data.table")
require("optparse")

option_list <- list(make_option(c("-t", "--datatag"), type="character", default=NULL, help="library_id", metavar="character"),
                    make_option(c("-m", "--metrics"), type="character", default=NULL, help="metrics_csv", metavar="character"),
                    make_option(c("-r", "--reads"), type="character", default=NULL, help="reads_csv", metavar="character"),
                    make_option(c("-o", "--outdir"), type="character", default=NULL, help="tip_probability_output", metavar="character")
)

opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

parse_bin_names <- function(bin_names) {
  # Remove corrupt_tree locus tag if it's there
  bin_names <- gsub('locus_', '', bin_names)
  chr <- gsub('([0-9]+|X|Y)_[0-9]+_[0-9]+', '\\1', bin_names)
  start <- as.numeric(gsub('([0-9]+|X|Y)_([0-9]+)_[0-9]+', '\\2', bin_names))
  end <- as.numeric(gsub('([0-9]+|X|Y)_([0-9]+)_([0-9]+)', '\\3', bin_names))
  data.frame(chr = chr, start = start, end = end)
}

wide_to_tidy_for_mat <- function(mat, chr_filter = NULL) {
  cnv_txt <- parse_bin_names(rownames(mat))
  mat <- cbind(cnv_txt, mat)
  if (!is.null(chr_filter))
    mat <- mat[mat$chr %in% chr_filter, ]
  reshape2::melt(mat, id.vars = c('chr', 'start', 'end'), value.name='copy_number', variable.name = 'cell_names')
}

sort_mat_by_bins <- function(the_mat) {
  # prevent scientific notation
  options(scipen=999) 

  chr = gsub('([0-9]+|X|Y)_[0-9]+_[0-9]+', '\\1', rownames(the_mat))
  start = as.numeric(gsub('([0-9]+|X|Y)_([0-9]+)_[0-9]+', '\\2', rownames(the_mat)))
  cnv_txt = data.frame(chr=chr, start=start, stringsAsFactors = F)
  the_mat <- cbind(cnv_txt, the_mat)

  # Sort the matrix by their chromosome (just inside the chromosome)
  the_mat$chr[the_mat$chr == 'X'] <- '40' 
  the_mat$chr[the_mat$chr == 'Y'] <- '55' 
  the_mat$chr <- as.numeric(the_mat$chr)
  the_mat <- the_mat[order(the_mat$chr, the_mat$start), ]
  the_mat$chr[the_mat$chr == '40'] <- 'X' 
  the_mat$chr[the_mat$chr == '55'] <- 'Y' 
  
  # Remove chr, start, end
  the_mat$chr <- NULL
  the_mat$start <- NULL
  the_mat
}

pad_chrs_cnv_mat <- function(the_mat, the_tag, the_path, ploidy = 2, use_cell_specific_ploidy = TRUE) {
  # Find the first bin in each chromosome
  bin_dat <- parse_bin_names(rownames(the_mat))
  uchr <- unique(bin_dat$chr)
  nchr <- length(uchr)
  # Generate the rownames
  new_names <- c()
  for (i in seq(nchr)) {
    new_name <- paste0(uchr[i], '_', 0, '_', 1) # It is always smaller
    new_names <- c(new_names, new_name)
    new_name <- paste0(uchr[i], '_', max(bin_dat$end) + 1, '_', max(bin_dat$end) + 2) # It is always larger
    new_names <- c(new_names, new_name)
  }
  
  # Add these columns and then sort
  if (use_cell_specific_ploidy) {
    pa <- get_ploidy_for_cells(the_tag, the_mat, the_path)
    pa <- pa[match(colnames(the_mat), pa$cell_names), ]
    stopifnot(all(pa$cell_names == colnames(the_mat)))
    tmat <- matrix(rep(pa$ploidy, length(new_names)), nrow = length(new_names), ncol = ncol(the_mat), byrow = T)
  } else {
    tmat <- matrix(2, nrow = length(new_names), ncol = ncol(the_mat))
  }
  
  colnames(tmat) <- colnames(the_mat)
  rownames(tmat) <- new_names
  qq <- as.data.frame(tmat)
  the_mat <- rbind(the_mat, tmat)
  the_mat <- sort_mat_by_bins(the_mat)
  the_mat
}

get_ploidy_for_cells <- function(datatag, data, outfile) {
  outpath <- file.path(outfile, datatag, '/ploidy.rds')
  
  if (file.exists(outpath))
    return(readRDS(outpath))
  
  the_mat <- data
  dmat <- wide_to_tidy_for_mat(the_mat)
  pa <- dmat %>% dplyr::count(cell_names, copy_number) %>% dplyr::group_by(cell_names) %>% dplyr::filter(n == max(n)) %>% dplyr::rename(ploidy = copy_number) %>% dplyr::select(cell_names, ploidy) %>% as.data.frame()
  pa$cell_names <- as.character(pa$cell_names)
  saveRDS(pa, outpath)
  
  pa
}

pip_CNV_2_corrupt <- function(datatag, clean_dat, outfile, pad_chr=FALSE, use_cell_specific_ploidy=FALSE) {
  dat <- clean_dat
  dat <- sort_mat_by_bins(dat)
  
  tag = ''
  out_dir <- file.path(outfile, datatag)
  dir.create(out_dir, showWarnings = F, recursive = T)
  out_path <- file.path(out_dir, paste0(tolower(datatag), tag, '_cnvs_diff.rds'))
  
  # pad chromosome?
  if (pad_chr) {
    dat <- pad_chrs_cnv_mat(the_mat = dat, the_tag = datatag, the_path = outfile, use_cell_specific_ploidy = use_cell_specific_ploidy)
  }
  
  # Compute diff
  mat_delta <- abs(dat[-c(nrow(dat)), ] - dat[-c(1), ])
  mat_delta[mat_delta > 1] <- 1
  
  mat_delta$loci <- rownames(mat_delta)
  rownames(mat_delta) <- NULL
  
  # cells,loci,tipInclusionProbabilities
  mat_delta <- reshape2::melt(mat_delta, id.vars = c('loci'), variable.name=c('cells'), value.name='tipInclusionProbabilities')
  mat_delta <- mat_delta[, c(2,1,3)]
  
  file_path <- file.path(out_dir, paste0(tolower(datatag), tag, '_cnvs_corrupt.csv'))
  if (pad_chr == FALSE) {
    file_path <- file.path(out_dir, paste0(tolower(datatag), tag, '_cnvs_corrupt_no_padding.csv'))
  }
  
#  if (!is.null(timepoint) & 1 == 0) {
#    mat_delta$loci = paste0('locus_', mat_delta$loci)
#  }
  
  #write.csv(mat_delta, file_path, row.names = F, quote = F)
  data.table::fwrite(mat_delta, file_path, row.names = F, quote = F)
  
  print(file_path)
  print("ready for corrupt-pypeliner_test")
}

## preprocessing from h5 / sc_pipeline results; from metrics, sort by quality>0.75. from reads, sort by map>0.99
df_metrics<-fread(opt$metrics)
df_reads<-fread(opt$reads)
high_quality_cell_ids<-subset(df_metrics, quality>=0.75)$cell_id
high_map_df_reads<-subset(df_reads, map>=0.99)
final_df_reads<-subset(high_map_df_reads, cell_id%in%high_quality_cell_ids)

important_df<-final_df_reads[, c("chr", "start", "end", "state", "cell_id")]
important_df$loci<-with(important_df, paste0(chr, "_", start, "_", end))
clean_dat<-acast(important_df, loci~cell_id, value.var = "state")
pip_CNV_2_corrupt(opt$datatag, clean_dat, opt$outdir)

## RUN:
# Rscript r_scripts/preprocessing/preprocessing.R -t A96192B -m raw_data/A96192B/A96192B_multiplier0_metrics.csv  -r raw_data/A96192B/A96192B_multiplier0_reads.csv -o /datadrive/corrupt-pypeliner_test/processed_data



