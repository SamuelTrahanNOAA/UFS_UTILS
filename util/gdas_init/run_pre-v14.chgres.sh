#!/bin/bash

#----------------------------------------------------------------
# Run chgres using pre-v14 gfs data (sigio/sfcio format
# from the spectral gfs).
#----------------------------------------------------------------

set -x

MEMBER=$1

FIX_FV3=$UFS_DIR/fix
FIX_ORO=${FIX_FV3}/orog
FIX_AM=${FIX_FV3}/am

WORKDIR=${WORKDIR:-$OUTDIR/work.${MEMBER}}

if [ "${MEMBER}" = "gdas" ] || [ "${MEMBER}" = "gfs" ]; then
  CTAR=${CRES_HIRES}
  INPUT_DATA_DIR="${EXTRACT_DIR}/${MEMBER}.${yy}${mm}${dd}/${hh}"
  if [ "${MEMBER}" = "gdas" ]; then
    ATMFILE="gdas1.t${hh}z.sanl"
    SFCFILE="gdas1.t${hh}z.sfcanl"
  else
    ATMFILE="gfs.t${hh}z.sanl"
    SFCFILE="gfs.t${hh}z.sfcanl"
  fi
else  
  CTAR=${CRES_ENKF}
  INPUT_DATA_DIR="${EXTRACT_DIR}/enkf.${yy}${mm}${dd}/${hh}/mem${MEMBER}"
  ATMFILE="siganl_${yy}${mm}${dd}${hh}_mem${MEMBER}"
  SFCFILE="sfcanl_${yy}${mm}${dd}${hh}_mem${MEMBER}"
fi

rm -fr $WORKDIR
mkdir -p $WORKDIR
cd $WORKDIR

source $GDAS_INIT_DIR/set_fixed_files.sh

cat << EOF > fort.41

&config
 fix_dir_target_grid="${FIX_ORO}/${ORO_DIR}/fix_sfc"
 mosaic_file_target_grid="${FIX_ORO}/${ORO_DIR}/${CTAR}_mosaic.nc"
 orog_dir_target_grid="${FIX_ORO}/${ORO_DIR}"
 orog_files_target_grid="${ORO_NAME}.tile1.nc","${ORO_NAME}.tile2.nc","${ORO_NAME}.tile3.nc","${ORO_NAME}.tile4.nc","${ORO_NAME}.tile5.nc","${ORO_NAME}.tile6.nc"
 data_dir_input_grid="${INPUT_DATA_DIR}"
 atm_files_input_grid="$ATMFILE"
 sfc_files_input_grid="$SFCFILE"
 vcoord_file_target_grid="${FIX_AM}/global_hyblev.l${LEVS}.txt"
 cycle_mon=$mm
 cycle_day=$dd
 cycle_hour=$hh
 convert_atm=.true.
 convert_sfc=.true.
 convert_nst=.false.
 input_type="gfs_sigio"
 tracers_input="spfh","o3mr","clwmr"
 tracers="sphum","o3mr","liq_wat"
/
EOF

$APRUN $EXEC_DIR/chgres_cube
rc=$?

if [ $rc != 0 ]; then
  exit $rc
fi

$GDAS_INIT_DIR/copy_coldstart_files.sh $MEMBER $OUTDIR $yy $mm $dd $hh $INPUT_DATA_DIR

rm -fr $WORKDIR

set +x
echo CHGRES COMPLETED FOR MEMBER $MEMBER

exit 0
