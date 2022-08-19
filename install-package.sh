#!/bin/bash

# USAGE
# ./install-package <spack package spec>

# TODO update gpu version of this script

# despite that this modulepath only includes x86_64,
# it seems to update the cache for other microarches as well
HARD_MODULEPATH="/modules/spack/share/spack/modules/linux-ubuntu20.04-x86_64:/modules/modulefiles"

SPACK_INSTALL_ARGS=$@
JOB_NAME="${SPACK_INSTALL_ARGS// /_}" # find and replace spaces with underscores
START_DT=$(date +"%Y-%m-%d-%H-%M-%S")

NUM_JOBS=0
for arch in $(<state/archlist.txt); do
    LOG_FILE="logs/${JOB_NAME}_${arch}_${START_DT}.out"
    echo "install #$(( $NUM_JOBS+1 )): Queuing job for architecture $arch..."
    echo $LOG_FILE
    sbatch --wait --job-name="build_$JOB_NAME" --constraint=$arch --output=$LOG_FILE \
            --export=SPACK_INSTALL_ARGS="$SPACK_INSTALL_ARGS" slurm/slurm-install-batch.sh\
            &\ # & means run this in the background
            > /dev/null
    ((NUM_JOBS++))
done

echo
echo "this might take a while. You can break out of this script and the installs will continue,"
echo "but you will have to check by hand that the installs were successful."
echo

ANY_FAILURES=0
for ((i=1; i<($NUM_JOBS+1); i++)); do
    # wait %i -> get the return code for background process i
    # multiple waits called in sequence will run in parallel
    # the background processes are indexed starting at 1
    wait %$i
    if [ ! $? -eq 0 ]; then
        echo "install # $i has failed!"
        ANY_FAILURES=1
    fi
done

if [ $ANY_FAILURES -eq 1 ]; then
    exit 1
fi

grep -qxF "$SPACK_INSTALL_ARGS" state/packagelist.txt || echo $SPACK_INSTALL_ARGS >> state/packagelist.txt
echo "regenerating Lmod spider cache using hard-coded modulepath. This may change someday!"
echo $HARD_MODULEPATH
# TODO hide implicit modules
/modules/lmod/lmod/lmod/libexec/update_lmod_system_cache_files -d /modules/lmod/cache $HARD_MODULEPATH
