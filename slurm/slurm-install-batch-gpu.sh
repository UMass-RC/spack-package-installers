#!/bin/bash
#SBATCH -c 8  # Number of Cores per Task
#SBATCH -t 1-0  # Job time limit
#SBATCH -p building
#SBATCH -G 1

echo "Loading spack environment..."
source /modules/spack/share/spack/setup-env.sh

echo spack --debug install --keep-stage -y $SPACK_PACKAGE_NAME
spack --debug install --keep-stage -y $SPACK_PACKAGE_NAME
