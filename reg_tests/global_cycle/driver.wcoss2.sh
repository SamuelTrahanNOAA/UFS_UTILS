#!/bin/bash

#-----------------------------------------------------------------------------
#
# Run global_cycle consistency test on WCOSS2.
#
# Set $WORK_DIR to your working directory.  Set the project code 
# and queue as appropriate.
#
# Invoke the script from the command line as follows:  ./$script
#
# Log output is placed in consistency.log??.  A summary is
# placed in summary.log
#
# A test fails when its output does not match the baseline files
# as determined by the 'nccmp' utility.  This baseline files are
# stored in HOMEreg.
#
#-----------------------------------------------------------------------------

set -x

compiler=${compiler:-"intel"}

source ../../sorc/machine-setup.sh > /dev/null 2>&1
module use ../../modulefiles
module load build.$target.$compiler
module list

WORK_DIR="${WORK_DIR:-/lfs/h2/emc/stmp/$LOGNAME}"

PROJECT_CODE="${PROJECT_CODE:-GFS-DEV}"
QUEUE="${QUEUE:-dev}"

#-----------------------------------------------------------------------------
# Should not have to change anything below.
#-----------------------------------------------------------------------------

DATA_DIR="${WORK_DIR}/reg-tests/global-cycle"

export HOMEreg=/lfs/h2/emc/eib/noscrub/George.Gayno/ufs_utils.git/reg_tests/global_cycle

export OMP_NUM_THREADS_CY=2

export APRUNCY="mpiexec -n 6 -ppn 6 --cpu-bind core --depth 2"

export NWPROD=$PWD/../..

reg_dir=$PWD

LOG_FILE=consistency.log
rm -f ${LOG_FILE}*

export DATA="${DATA_DIR}/test1"
export COMOUT=$DATA
TEST1=$(qsub -V -o ${LOG_FILE}01 -e ${LOG_FILE}01 -q $QUEUE -A $PROJECT_CODE -l walltime=00:05:00 \
        -N c768.fv3gfs -l select=1:ncpus=12:mem=8GB $PWD/C768.fv3gfs.sh)

export DATA="${DATA_DIR}/test2"
export COMOUT=$DATA
TEST2=$(qsub -V -o ${LOG_FILE}02 -e ${LOG_FILE}02 -q $QUEUE -A $PROJECT_CODE -l walltime=00:05:00 \
        -N c768.lndincsoil -l select=1:ncpus=12:mem=1GB $PWD/C768.lndincsoil.sh)

export DATA="${DATA_DIR}/test3"
export COMOUT=$DATA
TEST3=$(qsub -V -o ${LOG_FILE}03 -e ${LOG_FILE}03 -q $QUEUE -A $PROJECT_CODE -l walltime=00:05:00 \
        -N c768.lndincsnow -l select=1:ncpus=12:mem=1GB $PWD/C768.lndincsnow.sh)

qsub -V -o ${LOG_FILE} -e ${LOG_FILE} -q $QUEUE -A $PROJECT_CODE -l walltime=00:01:00 \
        -N cycle_summary -l select=1:ncpus=2:mem=100MB -W depend=afterok:$TEST1:$TEST2:$TEST3 << EOF
#!/bin/bash
cd $reg_dir
grep -a '<<<' ${LOG_FILE}??  > summary.log
EOF

exit
