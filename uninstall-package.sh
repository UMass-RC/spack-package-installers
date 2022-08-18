#!/bin/bash

# USAGE
# ./install-package <spack package spec>

SPACK_PACKAGE_NAME=$*
JOB_NAME="uninstall_${SPACK_PACKAGE_NAME// /_}" # find and replace spaces with underscores

IFS=$'\n' read -d '' -r -a lines < state/archlist.txt

for i in "${lines[@]}"
do
    echo "Queuing job for architecture $i..."
    sbatch --job-name="$JOB_NAME" --constraint=$i --output=logs/$JOB_NAME-$i.out \
	    --export=SPACK_PACKAGE_NAME="$SPACK_PACKAGE_NAME" slurm/slurm-uninstall-batch.sh
    echo log file: logs/$JOB_NAME-$i.out
done

# find and replace the package name from the package list
grep -RiIl state/packagelist | xargs sed -i 's:^${SPACK_PACKAGE_NAME}$::g'
