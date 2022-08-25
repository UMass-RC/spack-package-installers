#!/bin/bash

# USAGE
# ./install-package [-a architecture] [-f]  [-g] <spack package spec>
# -a install for a specific architecture rather than read from state/archlist.txt
# -f spack install --fresh
# -g get a GPU for the job

# you can also export EXTRA_SPACK_ARGS and they will be inserted
# you can also export EXTRA_SBATCH_ARGS and they will be inserted
# if you want to export variables to this script, start another nested shell,
# because `exit` will kill your shell

while getopts "a:fg" option; do
    case $option in
        a) USER_ARCH=$OPTARG;;
        f) EXTRA_SPACK_ARGS="$EXTRA_SPACK_ARGS --fresh";; # todo no duplicates
        g) EXTRA_SBATCH_ARGS="$EXTRA_SBATCH_ARGS -G 1";; # todo no duplicates
    esac
done
shift $(($OPTIND - 1)) # remove processed args from $@
$@=$(echo $$@ | sed 's/ *$//g') # strip trailing whitespace
$@=$(echo $$@ | sed 's/^ *//g') # strip leading whitespace

NUM_CORES=8
TIME="1-0"
PARTITION="building"

SPACK_INSTALL_ARGS=$@
# if EXTRA_SPACK_ARGS is defined, prepend it to SPACK_INSTALL_ARGS
if [ ! -z ${EXTRA_SPACK_ARGS+x} ]; then
    SPACK_INSTALL_ARGS="$EXTRA_SPACK_ARGS $SPACK_INSTALL_ARGS"
fi

JOB_NAME="${SPACK_INSTALL_ARGS//-}" # remove dashes
JOB_NAME="${JOB_NAME// /_}" # find and replace spaces with underscores
RANDOM_STR=$( echo $RANDOM | md5sum | head -c 5; echo;)

echo "Loading spack environment..."
source /modules/spack/share/spack/setup-env.sh
echo

NUM_JOBS=0
arches=$(<state/archlist.txt)
# if $USER_ARCH is defined, then overwrite the arch list
if [ ! -z ${USER_ARCH+x} ]; then
    arches=($USER_ARCH)
fi
for arch in $arches; do
    LOG_FILE="logs/${JOB_NAME}_${arch}_${RANDOM_STR}.out" # random so that logs don't overwrite
    echo "install #$(( $NUM_JOBS+1 ))"
    echo "$LOG_FILE"
    echo sbatch --wait --job-name="build_$JOB_NAME" --constraint=$arch --output=$LOG_FILE \
            ${EXTRA_SBATCH_ARGS} --partition=$PARTITION --cpus-per-task=$NUM_CORES --time=$TIME\
            --export=SPACK_INSTALL_ARGS="$SPACK_INSTALL_ARGS" slurm/slurm-install-batch.sh
    sbatch --wait --job-name="build_$JOB_NAME" --constraint=$arch --output=$LOG_FILE \
            ${EXTRA_SBATCH_ARGS} --partition=$PARTITION --cpus-per-task=$NUM_CORES --time=$TIME\
            --export=SPACK_INSTALL_ARGS="$SPACK_INSTALL_ARGS" slurm/slurm-install-batch.sh &
            # & means run this in the background
    ((NUM_JOBS++))
done

echo
echo "this might take a while. You can break out of this script and the installs will continue,"
echo "but you will have to manually check the installs were successful, and do the post install cleanup."
echo "use tmux to detach a session and let it run in the background."
echo

ANY_FAILURES=0
ANY_SUCCESSES=0
for ((i=1; i<($NUM_JOBS+1); i++)); do
    # wait %i -> get the return code for background process i
    # multiple waits called in sequence will run in parallel
    # the background processes are indexed starting at 1
    # if a job is held up in the queue then the `wait`s after it won't start until it gets out
    wait %$i
    if [ $? -eq 0 ]; then
        echo "install #$i was a success!"
        ANY_SUCCESSES=1
    else
        echo "install #$i has failed!"
        ANY_FAILURES=1
    fi
done

if [ $ANY_FAILURES -eq 1 ] && [ $ANY_SUCCESSES -eq 1 ]; then
    echo "ACTION REQUIRED"
    echo "some installs succeeded but some failed! You will have to clean this up by hand."
fi

if [ $ANY_FAILURES -eq 1 ]; then
    exit 1
fi

./post-install-cleanup.sh
