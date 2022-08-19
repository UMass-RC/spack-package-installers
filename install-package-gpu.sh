#!/bin/bash

# USAGE
# ./install-package <spack package spec>

# despite that this modulepath only includes x86_64,
# it seems to update the cache for other microarches as well
HARD_MODULEPATH="/modules/spack/share/spack/modules/linux-ubuntu20.04-x86_64:/modules/modulefiles"

SPACK_INSTALL_ARGS=$@
JOB_NAME="${SPACK_INSTALL_ARGS// /_}" # find and replace spaces with underscores
RANDOM_STR=$( echo $RANDOM | md5sum | head -c 5; echo;)

echo "Loading spack environment..."
source /modules/spack/share/spack/setup-env.sh
echo

NUM_JOBS=0
for arch in $(<state/archlist.txt); do
    LOG_FILE="logs/${JOB_NAME}_${arch}_${RANDOM_STR}.out" # random so that logs don't overwrite
    echo "install #$(( $NUM_JOBS+1 )): $LOG_FILE"
    sbatch --wait --job-name="build_$JOB_NAME" --constraint=$arch --output=$LOG_FILE \
            --export=SPACK_INSTALL_ARGS="$SPACK_INSTALL_ARGS" slurm/slurm-install-batch-gpu.sh\
            & # & means run this in the background
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
    # if a job is held up in the queue then the `wait`s after it won't start until it gets out
    wait %$i
    if [ ! $? -eq 0 ]; then
        echo "install #$i has failed!"
        ANY_FAILURES=1
    fi
done

if [ $ANY_FAILURES -eq 1 ]; then
    exit 1
fi

# add spack args to the packagelist
grep -qxF "$SPACK_INSTALL_ARGS" state/packagelist.txt || echo $SPACK_INSTALL_ARGS >> state/packagelist.txt
# remove implicit (dependent) modules from `module av`
./hide-implicit-mods.py
echo "regenerating Lmod spider cache using hard-coded modulepath. This may change someday!"
echo $HARD_MODULEPATH
/modules/lmod/lmod/lmod/libexec/update_lmod_system_cache_files -d /modules/lmod/cache $HARD_MODULEPATH
