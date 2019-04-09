myscriptdir=/lustre/scratch/wbic-beta/tec31/SERPENT_scripts/SERPENT
clusterid=HPHI

submit=${myscriptdir}/SERPENT_submit_hphi_short.sh
prepare=${myscriptdir}/SERPENT_prepare.sh
func=${myscriptdir}/Preprocessing_mainfunction_7T.m
subjs_def=${myscriptdir}/SERPENT_subjects_parameters.m

#! declare -a steporder=("raw" "skullstrip" "realign" "topup" "cat12")
#! subjects_to_process=($(seq 1 1 10))
subjects_to_process=($(seq 5 1 5))

prevstep=raw_nocopy
step=fmriprep

jobIDs=""

cd slurmoutputs
for this_subj in ${subjects_to_process[@]}
do 
this_job_id=$(sbatch --parsable ${submit} ${prepare} ${func} ${subjs_def} ${this_subj} ${clusterid} ${prevstep} ${step})
#! echo ${submit} ${prepare} ${func} ${subjs_def} ${this_subj} ${clusterid} ${prevstep} ${step} #! for debug this will list all the sbatch submissions, to test, copy one line and paste after "sbatch "
jobIDs="$jobIDs $this_job_id"
done

echo "submitted job stage" ${step} "polling for output before moving on"
${myscriptdir}/waitForSlurmJobs.pl 1 10 $jobIDs
for this_job in ${jobIDs[@]}
do
this_job_outcome=$(sacct -j ${this_job} --format='State' -n)
job_state=`echo $this_job_outcome | awk '{print $1}'` 
if [ "$job_state" == "FAILED" ] 
    then
        echo "SLURM submission failed - jobs went into error state"
        exit 1;
fi
done

cd ..

