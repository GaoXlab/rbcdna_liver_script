#!/bin/bash
#SBATCH -J R
#SBATCH -p amd-ep2,amd-ep2-short,intel-sc3
#SBATCH -q normal
#SBATCH --mem=10G
#SBATCH -c 1

module load R/4.2.1
module load gcc/11.2.0 

# normalized data
Rscript scripts/STEP1_normalization.R --path modelData --files trn.8m.nodup.q30.bam.10kb_readcounts.txt --output_name Input_raw_nor
Rscript scripts/STEP1_normalization.R --path modelData --files test.8m.nodup.q30.bam.10kb_readcounts.txt --output_name Input_raw_nor.test

# select features
Rscript scripts/STEP2_SelectedSig.R --path modelData --files Input_raw_nor.RData --samples_type1 D_Ctrl --samples_type2 D_tDEN --pvalue.threshold 0.05 --output results

