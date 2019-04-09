#!/bin/bash
#Swap voxels and header in bad image 1 according to parameters in good image 2

#badfile=/scratch/wbic-beta/spj24/serpent/sub-S7P05/sub-S7P05_vol0.nii.gz
#goodfile=/scratch/wbic-beta/spj24/serpent/sub-S7C03/sub-S7C03_ses-20181025_task-SERPENT_acq-cmrr_run-1_bold_vol0.nii.gz
badfile=$1
goodfile=$2

badfile=`remove_ext "${badfile}"`
badfileswap="${badfile}"_swap
fslswapdim "${badfile}" x z -y "${badfileswap}"
sform=`fslorient -getsform ${goodfile}`
fslorient -setsform ${sform} "${badfileswap}"
fslorient -copysform2qform "${badfileswap}"

