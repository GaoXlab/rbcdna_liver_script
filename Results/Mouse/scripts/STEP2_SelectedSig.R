#!/usr/bin/env Rscript
## set the right library paths
source('scripts/utils.r')
library(optparse)
library(dplyr)
library(patchwork)
library(cowplot)
library(reshape2)
library(stringr)
library(ggpubr)
# library(ggbiplot)
library(pheatmap)
library(ggplot2)
# library(factoextra)
library(RColorBrewer)
library(RCurl)
library(bitops)
library(later)
option_list = list(
    make_option(c("-p", "--path"), type = "character", default = "./modelData/",  help = ""),
    make_option(c("-i", "--files"), type = "character", default = "Input_raw_nor.RData",  help = ""),
    make_option(c("-t", "--samples_type1"), type = "character", default = "D_Ctrl",  help = ""),
    make_option(c("-q", "--samples_type2"), type = "character", default = "D_tDEN",  help = ""),
    make_option(c("-f", "--foldchange_or_not"), type = "character", default = "yes",  help = "Option is yes/ no"),
    make_option(c("-s", "--test.use"), type = "character", default = "anova",  help = "Option is anova/ wilcoxon/ null"),
    make_option(c("-a", "--pvalue.threshold"), type = "double", default = 0.05,  help = "Pvalue cutoff for significant regions"),
    make_option(c("-d", "--lg2fc.threshold"), type = "integer", default = 1,  help = "Option is 1"),
    make_option(c("-o", "--output"), type = "character", default = "results",  help = "Prefix of all files name")
)

parseobj = OptionParser(option_list=option_list)
opt = parse_args(parseobj)

load(str_c(as.character(opt$path),"/",as.character(opt$files)))
files.temp <- nor # read.table(str_c(as.character(opt$path),"/",as.character(opt$files)),head=T,sep="\t", row.names=1)
foldchange_or_not <- as.character(opt$foldchange_or_not)
test.use <- as.character(opt$test.use)
pvalue.threshold <- as.numeric(opt$pvalue.threshold)
lg2fc.threshold <- as.numeric(opt$lg2fc.threshold)
Pseudocount=0

title <- str_c(as.character(opt$output))
dir.create(title)
setwd(title)

###########################################################################
# Select regions and Default output:table and pvalueFC plot#
###########################################################################
D_samples_type1 <- files.temp[, grep(opt$samples_type1, colnames(files.temp))]
D_samples_type2 <- files.temp[, grep(opt$samples_type2, colnames(files.temp))]

grp2vgrp1 <- FindFeatures(D_samples_type1,D_samples_type2,test.use=test.use,lg2fc.threshold,pvalue.threshold,Pseudocount,title)
