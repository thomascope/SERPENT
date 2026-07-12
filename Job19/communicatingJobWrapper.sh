#!/bin/sh
# This wrapper script is intended to be submitted to Slurm to support
# communicating jobs.
#
# This script uses the following environment variables set by the submit MATLAB code:
# PARALLEL_SERVER_CMR         - the value of ClusterMatlabRoot (may be empty)
# PARALLEL_SERVER_MATLAB_EXE  - the MATLAB executable to use
# PARALLEL_SERVER_MATLAB_ARGS - the MATLAB args to use
# PARALLEL_SERVER_NUM_THREADS - number of cores needed per worker
# PARALLEL_SERVER_DEBUG       - used to debug problems on the cluster
#
# The following environment variables are forwarded through mpiexec:
# PARALLEL_SERVER_DECODE_FUNCTION     - the decode function to use
# PARALLEL_SERVER_STORAGE_LOCATION    - used by decode function
# PARALLEL_SERVER_STORAGE_CONSTRUCTOR - used by decode function
# PARALLEL_SERVER_JOB_LOCATION        - used by decode function
#
# The following environment variables are set by Slurm:
# SLURM_NODELIST - list of hostnames allocated to this Slurm job

# Copyright 2017-2022 The MathWorks, Inc.

# If PARALLEL_SERVER_ environment variables are not set, assign any
# available values with form MDCE_ for backwards compatibility
PARALLEL_SERVER_CMR=${PARALLEL_SERVER_CMR:="${MDCE_CMR}"}
PARALLEL_SERVER_MATLAB_EXE=${PARALLEL_SERVER_MATLAB_EXE:="${MDCE_MATLAB_EXE}"}
PARALLEL_SERVER_MATLAB_ARGS=${PARALLEL_SERVER_MATLAB_ARGS:="${MDCE_MATLAB_ARGS}"}
PARALLEL_SERVER_DEBUG=${PARALLEL_SERVER_DEBUG:="${MDCE_DEBUG}"}

# Echo the nodes that the scheduler has allocated to this job:
echo The scheduler has allocated the following nodes to this job: ${SLURM_NODELIST:?"Node list undefined"}

# Create full path to mw_mpiexec if needed.
FULL_MPIEXEC=${PARALLEL_SERVER_CMR:+${PARALLEL_SERVER_CMR}/bin/}mw_mpiexec

# Label stdout/stderr with the rank of the process
MPI_VERBOSE=-l

# Increase the verbosity of mpiexec if PARALLEL_SERVER_DEBUG is true
if [ "X${PARALLEL_SERVER_DEBUG}X" = "XtrueX" ] ; then
    MPI_VERBOSE="${MPI_VERBOSE} -v -print-all-exitcodes"
fi

# Unset the hostname variables to ensure they don't get forwarded by mpiexec
unset HOST HOSTNAME

# Construct the command to run.
CMD="\"${FULL_MPIEXEC}\" -bind-to core:${PARALLEL_SERVER_NUM_THREADS} ${MPI_VERBOSE} -n ${PARALLEL_SERVER_TOTAL_TASKS} \
    \"${PARALLEL_SERVER_MATLAB_EXE}\" ${PARALLEL_SERVER_MATLAB_ARGS}"

# Echo the command so that it is shown in the output log.
echo $CMD

# Execute the command.
eval $CMD

# Echo the code mpiexec exited with. If MATLAB doesn't shutdown cleanly, this
# may be nonzero. We don't want to exit here with a nonzero code as this will
# cause the job to appear as failed in sacct, even though the user's work may
# have succeeded.
MPIEXEC_EXIT_CODE=${?}
echo "MPIEXEC exited with code: ${MPIEXEC_EXIT_CODE}"
exit 0
