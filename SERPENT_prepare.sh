#!/bin/bash
#
#PBS -N Matlab
#PBS -m be 
#PBS -k oe
 
date

func=$1
subjs_def=$2
ref=$3
environment=$4
prevStep=$5
Step=$6

echo "working on file ${ref}"

#INCLUDE MATLAB CALL

#We may have to include -nojvm or there is a memory error
#-nodesktop -nosplash -nodisplay -nojvm together work
#Some Matlab functions like gzip require java so cannot
#use -nojvm option

if environment == 'HPC'
    then
        /usr/local/Cluster-Apps/matlab/R2017b/bin/matlab -nodesktop -nosplash -nodisplay <<EOF
elif environment == 'CBU'
    then
        matlab -nodesktop -nosplash -nodisplay <<EOF
fi

[pa,af,~]=fileparts('${func}');
addpath(pa);
disp(['Path is ' pa])
disp(['Function is ' af])
disp(['Subject definition function is ${subjs_def}])

do_definition_func=sprintf('%s(%s)','${subjs_def}')
addpath(pwd)

if strcmp(${environment},'CBU')
    rawpathstem = '/imaging/tc02/';
    preprocessedpathstem = '/imaging/tc02/SERPENT_preprocessed/';
elseif strcmp(${environment},'HPC')
    rawpathstem = '/rds/user/tec31/hpc-work/SERPENT/rawdata/';
    preprocessedpathstem = '/rds/user/tec31/hpc-work/SERPENT/preprocessed/';
end

dofunc=sprintf('%s(%s)',af,'${ref}')
eval(dofunc)
;exit
EOF