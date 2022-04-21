#!/bin/bash
#SBATCH -c 8  # Number of Cores per Task
#SBATCH -t 12:00:00  # Job time limit
#SBATCH -p building

echo "Loading spack environment..."
source /modules/spack/share/spack/setup-env.sh

echo "Installing spack package ${SPACK_PACKAGE_NAME}..."

spack install -y $SPACK_PACKAGE_NAME
spack -y gc