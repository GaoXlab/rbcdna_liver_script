#!/bin/bash

SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
FEATURE_SELECTION_OUTPUT_DIR=$(cd $SCRIPT_DIR/../results/2_FeatureSelection; pwd)
FEATURE_REDUCTION_OUTPUT_DIR=$(cd $SCRIPT_DIR/../results/3_FeatureReduction; pwd)
FEATURE_CLASSIFICATION_DIR=$(cd $SCRIPT_DIR/../results/4_Classification; pwd)
FILE_LOCATION_BAMS=`cd $SCRIPT_DIR/../../bam;pwd`
MODEL_DATA_DIR=$(cd $SCRIPT_DIR/../modelData; pwd)

message() {
  local message="$1"
  echo $message
}

echo "Making train.tab"
OUTPUT_PREFIX=$1
TYPE=$OUTPUT_PREFIX

python $SCRIPT_DIR/step2_hcc.py $TYPE `pwd`

# repeat 40 times for random ids
if [ -f "all.${TYPE}.sample.info.1" ]; then
    message "Skip gen repeat 80 ids"
else
    message "Gen repeat 80 ids"
    php $SCRIPT_DIR/repeat_p80.php $MODEL_DATA_DIR/${TYPE}.pos.ids.txt $MODEL_DATA_DIR/${TYPE}.neg.ids.txt 50 "all.${TYPE}.sample.info"
    message "Gen repeat 80 ids finished"
fi

# calc 10m feature scores and select top 1000 for 40 random repeat
seq 1 50 | xargs -n 1 -I %1 -P 3 $SCRIPT_DIR/fs.sh $TYPE %1

# merge all 40 top 1000 feature scores
php $SCRIPT_DIR/merge_p80.php $TYPE

$SCRIPT_DIR/bed_select all.$TYPE.bed all.$TYPE.bed.out 1000

cat all.$TYPE.bed.out|cut -f1-3 > $FEATURE_SELECTION_OUTPUT_DIR/all.$TYPE.bed.out

mv all.$TYPE.bed $FEATURE_SELECTION_OUTPUT_DIR
# clean up workspace and backup all random ids
cp "all.${TYPE}.sample.info".* $FEATURE_SELECTION_OUTPUT_DIR
#rm train.tab.*

build selected feature bed for feature selection
$SCRIPT_DIR/new_mode.sh "manu_{$TYPE}_2025" $FEATURE_SELECTION_OUTPUT_DIR/all.${TYPE}.bed.out
cd $FILE_LOCATION_BAMS
ls *.nodup.q30.bam 2>/dev/null | cut -f 1 -d . | xargs -n 1 -P 8 -I %1 $SCRIPT_DIR/tab.cpm.sh "manu_${TYPE}_2025" %1
$SCRIPT_DIR/make_all_tab.sh manu_${TYPE}_2025 all.${TYPE}.tab
cp all.${TYPE}.tab $FEATURE_SELECTION_OUTPUT_DIR

cd $FEATURE_SELECTION_OUTPUT_DIR
tar zcf $OUTPUT_PREFIX.sample.info.tar.gz all.$TYPE.sample.info.*
rm $FEATURE_SELECTION_OUTPUT_DIR/all.$TYPE.sample.info.*
