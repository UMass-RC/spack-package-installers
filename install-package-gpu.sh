#!/bin/bash

# USAGE
# ./install-package <spack package spec>

#SPACK_PACKAGE_NAME=$1
SPACK_PACKAGE_NAME=$*
JOB_NAME="build_${SPACK_PACKAGE_NAME// /_}" # find and replace spaces with underscores

#echo "spack install $SPACK_PACKAGE_NAME"
#[[ "$(read -e -p 'is this correct? [y/N]> '; echo $REPLY)" == [Yy]* ]] || exit


IFS=$'\n' read -d '' -r -a lines < state/archlist.txt

for i in "${lines[@]}"
do
    echo "Queuing job for architecture $i..."
    sbatch --job-name="$JOB_NAME" --constraint=$i --output=logs/$JOB_NAME-$i.out \
	    --export=SPACK_PACKAGE_NAME="$SPACK_PACKAGE_NAME" slurm/slurm-install-batch-gpu.sh
    echo log file: logs/$JOB_NAME-$i.out
done

# add to package file if not already there
grep -qxF "$SPACK_PACKAGE_NAME" state/packagelist.txt || echo $SPACK_PACKAGE_NAME >> state/packagelist.txt
