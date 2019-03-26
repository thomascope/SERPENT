myscriptdir=/rds/user/tec31/hpc-work/SERPENT
clusterid=HPC

submit=${myscriptdir}/SERPENT_submit_himemlongtime.sh
prepare=${myscriptdir}/SERPENT_prepare.sh
func=${myscriptdir}/Preprocessing_mainfunction_7T.m
subjs_def=${myscriptdir}/SERPENT_subjects_parameters.m

#! declare -a steporder=("raw" "skullstrip" "realign" "topup" "cat12")
#! subjects_to_process=($(seq 1 1 10))
subjects_to_process=($(seq 1 1 2))

prevstep=raw
step=skullstrip

count=0
jobIDs=""

for this_subj in ${subjects_to_process[@]}
do 
this_job_id = 'sbatch ${submit} ${prepare} ${func} ${subjs_def} ${this_subj} ${clusterid} ${prevstep} ${step}'
#! echo ${submit} ${prepare} ${func} ${subjs_def} ${this_subj} ${clusterid} ${prevstep} ${step} #! for debug this will list all the sbatch submissions, to test, copy one line and paste after "sbatch "
jobIDs="$jobIDs $this_job_id"
done

${myscriptdir}/waitForSlurmJobs.pl 1 10 $jobIDs
if [[ ! $? -eq 0 ]];
    then
        echo "SLURM submission failed - jobs went into error state"
        exit 1;
fi

prevstep=skullstrip
step=realign

for this_subj in ${subjects_to_process[@]}
do 
this_job_id = 'sbatch ${submit} ${prepare} ${func} ${subjs_def} ${this_subj} ${clusterid} ${prevstep} ${step}'
#! echo ${submit} ${prepare} ${func} ${subjs_def} ${this_subj} ${clusterid} ${prevstep} ${step} #! for debug this will list all the sbatch submissions, to test, copy one line and paste after "sbatch "
jobIDs="$jobIDs $this_job_id"
done

${myscriptdir}/waitForSlurmJobs.pl 1 10 $jobIDs
if [[ ! $? -eq 0 ]];
    then
        echo "SLURM submission failed - jobs went into error state"
        exit 1;
fi

prevstep=realign
step=topup

for this_subj in ${subjects_to_process[@]}
do 
this_job_id = 'sbatch ${submit} ${prepare} ${func} ${subjs_def} ${this_subj} ${clusterid} ${prevstep} ${step}'
#! echo ${submit} ${prepare} ${func} ${subjs_def} ${this_subj} ${clusterid} ${prevstep} ${step} #! for debug this will list all the sbatch submissions, to test, copy one line and paste after "sbatch "
jobIDs="$jobIDs $this_job_id"
done

${myscriptdir}/waitForSlurmJobs.pl 1 10 $jobIDs
if [[ ! $? -eq 0 ]];
    then
        echo "SLURM submission failed - jobs went into error state"
        exit 1;
fi

prevstep=realign
step=topup

for this_subj in ${subjects_to_process[@]}
do 
this_job_id = 'sbatch ${submit} ${prepare} ${func} ${subjs_def} ${this_subj} ${clusterid} ${prevstep} ${step}'
#! echo ${submit} ${prepare} ${func} ${subjs_def} ${this_subj} ${clusterid} ${prevstep} ${step} #! for debug this will list all the sbatch submissions, to test, copy one line and paste after "sbatch "
jobIDs="$jobIDs $this_job_id"
done

${myscriptdir}/waitForSlurmJobs.pl 1 10 $jobIDs
if [[ ! $? -eq 0 ]];
    then
        echo "SLURM submission failed - jobs went into error state"
        exit 1;
fi

prevstep=topup
step=reslice

for this_subj in ${subjects_to_process[@]}
do 
this_job_id = 'sbatch ${submit} ${prepare} ${func} ${subjs_def} ${this_subj} ${clusterid} ${prevstep} ${step}'
#! echo ${submit} ${prepare} ${func} ${subjs_def} ${this_subj} ${clusterid} ${prevstep} ${step} #! for debug this will list all the sbatch submissions, to test, copy one line and paste after "sbatch "
jobIDs="$jobIDs $this_job_id"
done

${myscriptdir}/waitForSlurmJobs.pl 1 10 $jobIDs
if [[ ! $? -eq 0 ]];
    then
        echo "SLURM submission failed - jobs went into error state"
        exit 1;
fi

prevstep=topup
step=cat12

for this_subj in ${subjects_to_process[@]}
do 
this_job_id = 'sbatch ${submit} ${prepare} ${func} ${subjs_def} ${this_subj} ${clusterid} ${prevstep} ${step}'
#! echo ${submit} ${prepare} ${func} ${subjs_def} ${this_subj} ${clusterid} ${prevstep} ${step} #! for debug this will list all the sbatch submissions, to test, copy one line and paste after "sbatch "
jobIDs="$jobIDs $this_job_id"
done

${myscriptdir}/waitForSlurmJobs.pl 1 10 $jobIDs
if [[ ! $? -eq 0 ]];
    then
        echo "SLURM submission failed - jobs went into error state"
        exit 1;
fi

prevstep=topup
step=coregister

for this_subj in ${subjects_to_process[@]}
do 
this_job_id = 'sbatch ${submit} ${prepare} ${func} ${subjs_def} ${this_subj} ${clusterid} ${prevstep} ${step}'
#! echo ${submit} ${prepare} ${func} ${subjs_def} ${this_subj} ${clusterid} ${prevstep} ${step} #! for debug this will list all the sbatch submissions, to test, copy one line and paste after "sbatch "
jobIDs="$jobIDs $this_job_id"
done

${myscriptdir}/waitForSlurmJobs.pl 1 10 $jobIDs
if [[ ! $? -eq 0 ]];
    then
        echo "SLURM submission failed - jobs went into error state"
        exit 1;
fi

prevstep=topup
step=normalisesmooth

for this_subj in ${subjects_to_process[@]}
do 
this_job_id = 'sbatch ${submit} ${prepare} ${func} ${subjs_def} ${this_subj} ${clusterid} ${prevstep} ${step}'
#! echo ${submit} ${prepare} ${func} ${subjs_def} ${this_subj} ${clusterid} ${prevstep} ${step} #! for debug this will list all the sbatch submissions, to test, copy one line and paste after "sbatch "
jobIDs="$jobIDs $this_job_id"
done

${myscriptdir}/waitForSlurmJobs.pl 1 10 $jobIDs
if [[ ! $? -eq 0 ]];
    then
        echo "SLURM submission failed - jobs went into error state"
        exit 1;
fi

prevstep=smooth8
step=SPM_uni

for this_subj in ${subjects_to_process[@]}
do 
this_job_id = 'sbatch ${submit} ${prepare} ${func} ${subjs_def} ${this_subj} ${clusterid} ${prevstep} ${step}'
#! echo ${submit} ${prepare} ${func} ${subjs_def} ${this_subj} ${clusterid} ${prevstep} ${step} #! for debug this will list all the sbatch submissions, to test, copy one line and paste after "sbatch "
jobIDs="$jobIDs $this_job_id"
done

${myscriptdir}/waitForSlurmJobs.pl 1 10 $jobIDs
if [[ ! $? -eq 0 ]];
    then
        echo "SLURM submission failed - jobs went into error state"
        exit 1;
fi

prevstep=smooth3
step=SPM_uni

for this_subj in ${subjects_to_process[@]}
do 
this_job_id = 'sbatch ${submit} ${prepare} ${func} ${subjs_def} ${this_subj} ${clusterid} ${prevstep} ${step}'
#! echo ${submit} ${prepare} ${func} ${subjs_def} ${this_subj} ${clusterid} ${prevstep} ${step} #! for debug this will list all the sbatch submissions, to test, copy one line and paste after "sbatch "
jobIDs="$jobIDs $this_job_id"
done

${myscriptdir}/waitForSlurmJobs.pl 1 10 $jobIDs
if [[ ! $? -eq 0 ]];
    then
        echo "SLURM submission failed - jobs went into error state"
        exit 1;
fi



