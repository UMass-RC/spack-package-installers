#!/bin/bash
#SBATCH -c 1  # Number of Cores per Task
#SBATCH -t 3:0:0  # Job time limit
#SBATCH -p building

echo jobid $SLURM_JOB_ID on host $(hostname) with arch $(/modules/spack/bin/spack arch) by user $(whoami) on $(date)

echo "Loading spack environment..."
source /modules/spack/share/spack/setup-env.sh

echo spack uninstall -y $SPACK_PACKAGE_NAME
spack uninstall -y $SPACK_PACKAGE_NAME

#--keep-stage will leave the build logs in /scratch, which will get cleaned up by /scratch anyways
# but it only does so if the installation was a success, and that's exactly when I don't want the logs

#--debug will say a lot of stuff and include tracebacks in spack codebase

#-V will spit out much (but not all) of the build log in the regular log. Good because the build log gets deleted.
