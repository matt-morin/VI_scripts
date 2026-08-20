#!/bin/bash
# =================================================
# ${HOME}/NGGPS/VI/VI_scripts/scripts_for_rt_gaea/rerun_VI.sh
#   --- Created by Matt Morin (UCAR/GFDL) 2026AUG18
#   --- Resets VI input/output data and launches run_retro.sh
#
# USAGE:
#   ---
#
# INPUT:
#   --- YMDHlist.txt
#
# NOTES:
#   ---
#
# TODO:
#   ---
#
# UPDATES:
#   [20???????]
# =================================================

echo "---------------------------------------------------------------------------------------------------------"
echo "----- STARTING rerun_VI.sh on $(hostname) at $(date)"
echo "---------------------------------------------------------------------------------------------------------"

export setx=${setx:-'set +x'}
PS4='+ [$(date +"%H:%M:%S")] run_reruns.sh line ${LINENO}: '
${setx}

# ++++++++++++++ START OF MAIN USER SETTINGS +++++++++++++++ #
YMDH=2025082100
modelname='SHiELD'      # SHiELD|T-SHiELD|T-SHiELD_new
RerunLabel='RERUN2'       # ORIG|RERUN|BAD2
#
rundir=${HOME}/NGGPS/VI/VI_scripts/scripts_for_rt_gaea
datefile=${rundir}/YMDHlist.txt
# ++++++++++++++  END  OF MAIN USER SETTINGS +++++++++++++++ #

# ++++++++++++++ START OF OTHER USER SETTINGS ++++++++++++++ #
case ${modelname} in
  SHiELD) GRID='C1536'
          ICDirbase=/gpfs/f5/gfdl_w/proj-shared/${USER}/SHiELD_INPUT_DATA/global.v202311/${GRID}
          ICfile=gfs_data.tile6.nc;;
  T-SHiELD) GRID='C768r10n4_atl_new'
            ICDirbase=/gpfs/f5/gfdl_w/proj-shared/${USER}/SHiELD_INPUT_DATA/variable.v202311/${GRID}
            ICfile=gfs_data.tile7.nc;;
  T-SHiELD_new) GRID='C768r10n5_atl_large'
            ICDirbase=/gpfs/f5/gfdl_w/proj-shared/${USER}/SHiELD_INPUT_DATA/variable.v202311/${GRID}
            ICfile=gfs_data.tile7.nc;;
esac
tcvitDir=${rundir}/tc_vitals/${modelname}
workDir=/gpfs/f5/gfdl_w/scratch/${USER}/vi_work/${modelname}
ICsNeeded=${rundir}/ICsNeeded.log
njob_max=200
njobs=$(squeue -h -u ${USER} -o '%10i %90j %12r' -t RUNNING,PENDING | grep -v 'JobHeldUser' | grep -c 'vi_ic_')
DATE="${YMDH:0:8}.${YMDH:8:2}Z"
# ++++++++++++++  END  OF OTHER USER SETTINGS ++++++++++++++ #

set +x
for var in YMDH modelname RerunLabel rundir datefile GRID ICDirbase ICfile tcvitDir workDir njob_max njobs
do
  if [ -n "${!var:-}" ] ; then
    echo "${var} is set to ${!var}"
  else
    echo "ERROR: ${var} is not set! Exiting..."; set -x
    exit 1
  fi
done
${setx}

cd ${ICDirbase}/${DATE}_IC/
rename -v --no-overwrite vi_ vi${RerunLabel}_ *vi_* #|| exit 1

cd ${workDir}/
mv -v --no-clobber ${YMDH} ${YMDH}_${RerunLabel} #|| exit 1

cd ${tcvitDir}/observed_all/
mv -v --no-clobber tcvitals_${YMDH}.txt tcvitals_${YMDH}_${RerunLabel}.txt #|| exit 1

cd ${tcvitDir}/processed/
mv -v --no-clobber ${YMDH} ${YMDH}_${RerunLabel} #|| exit 1

cd ${HOME}/NGGPS/VI/VI_scripts/scripts_for_rt_gaea/
sed -i "s/xxx${YMDH}/${YMDH}/g" YMDHlist.txt
#./run_retro.sh
echo "REMINDER: Modify run_retro.sh if needed --- TODO: Automate this"

set +x
echo "---------------------------------------------------------------------------------------------------------"
echo "----- ENDING   rerun_VI.sh on $(hostname) at $(date)"
echo "---------------------------------------------------------------------------------------------------------"
