#!/bin/bash
#
#PBS -N Matlab
#PBS -m be 
#PBS -k oe
 
date

func=$1
subjs_def=$2
ref=$3
clusterid=$4
prevStep=$5
Step=$6

echo "working on file ${ref}"
echo "The workspace going into this is ${func} ${subjs_def} ${ref} ${clusterid} ${prevStep} ${Step}"

#INCLUDE MATLAB CALL

#We may have to include -nojvm or there is a memory error
#-nodesktop -nosplash -nodisplay -nojvm together work
#Some Matlab functions like gzip require java so cannot
#use -nojvm option

matlab -nodesktop -nosplash -nodisplay <<EOF

[pa,af,~]=fileparts('${func}');
addpath(pa);
disp(['Path is ' pa])
disp(['Function is ' af])
disp(['Subject definition function is ${subjs_def}'])
disp(['Environment is ${clusterid}'])
disp(['Previous step is ${prevStep}'])
disp(['This step is ${Step}'])

do_definition_func=sprintf('%s','${subjs_def}')
[pa2,af2,~] = fileparts(do_definition_func);
addpath(pa2)
eval(af2)
addpath(pwd)

if strcmp('${clusterid}','CBU')
    rawpathstem = '/imaging/tc02/';
    preprocessedpathstem = '/imaging/tc02/SERPENT_preprocessed/';
elseif strcmp('${clusterid}','HPC')
    rawpathstem = '/rds/user/tec31/hpc-work/SERPENT/rawdata/';
    preprocessedpathstem = '/rds/user/tec31/hpc-work/SERPENT/preprocessed/';
end

dofunc=sprintf('%s(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)',af,'''${Step}''','''${prevStep}''','''${clusterid}''','preprocessedpathstem','rawpathstem','subjects','${ref}','fullid','basedir','blocksin','blocksin_folders','blocksout','minvols','dates','group');
disp(['Submitting the following command: ' dofunc])
eval(dofunc)
;exit
EOF