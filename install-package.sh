#!/bin/bash

# USAGE
# ./install-package <spack package spec>

SPACK_PACKAGE_NAME=$1

IFS=$'\n' read -d '' -r -a lines < state/archlist.txt

for i in "${lines[@]}"
do
    echo "Queuing job for architecture $i..."

    sbatch --job-name="build-${SPACK_PACKAGE_NAME}" --constraint=$i --output=logs/$SPACK_PACKAGE_NAME-$i.out --export=SPACK_PACKAGE_NAME=$SPACK_PACKAGE_NAME slurm/slurm-install-batch.sh
done

# add to package file if not already there
grep -qxF $SPACK_PACKAGE_NAME state/packagelist.txt || echo $SPACK_PACKAGE_NAME >> state/packagelist.txt

# finished submitting jobs
echo "Remember to run spack gc afterwards to remove excess build dependencies"
