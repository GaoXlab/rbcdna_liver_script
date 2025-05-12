# This file shows how to use the pipeline module to reproduce the results of the paper.

# 1. directory structure
```text
├── bam
├── modelData
│   └── empty
│       ├── cleaned
│       └── origin
├── results
│   ├── 2_FeatureSelection
│   ├── 3_FeatureReduction
│   └── 4_Classification
└── script 
```
You should put bam files in bam directory, and the module data in the modelData directory. The results will be saved in the results directory.

# 2. run the pipeline
```bash
# Build 10k cpm data
./script/step1.sh

# hcc pipeline
# 1. Feature selection from whole genome features
./script/step2_hcc.sh hcc
# 2. Feature reduction and train model
python ./script/step3_hcc.py hcc `pwd`

## for the independent test set
python ./script/step3_hcc_test.py hcc `pwd` test 
python ./script/step3_hcc_test.py hcc `pwd` ind
``` 
Feature selection results will be saved in the 2_FeatureSelection directory, feature reduction results will be saved in the 3_FeatureReduction directory, and classification results will be saved in the 4_Classification directory.