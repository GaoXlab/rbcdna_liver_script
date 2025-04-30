#!/usr/bin/env Rscript
## set the right library paths
library(optparse)
library(stringr)
library(stringr)
option_list = list(
    make_option(c("-p", "--path"), type = "character", default = "./",  help = ""),
    make_option(c("-i", "--files"), type = "character", default = "",  help = ""),
    make_option(c("-o", "--output_name"), type = "character", default = "",  help = "")
)

parseobj = OptionParser(option_list=option_list)
opt = parse_args(parseobj)
path <- as.character(opt$path)
file <- as.character(opt$file)

# path = './modelData'
# file = 'Mus1.8m.nodup.q30.bam.10kb_readcounts.txt'
raw = read.table(str_c(path, '/', file), sep='\t', head=TRUE, row.names=1)
raw = raw[, 4:ncol(raw)] # remove chr,start,end

nor <- apply(raw, 2, function(x) (x / sum(x)) * 10000000)
nor <- as.data.frame(nor)
print(dim(nor))

save(raw, nor, file=str_c(path, '/',as.character(opt$output_name),'.RData'))
