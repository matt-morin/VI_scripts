#!/bin/bash
# =================================================
# ${HOME}/NGGPS/VI/VI_scripts/scripts_for_rt_gaea_DEV/run_retro.sh
#   --- Created by Matt Morin (UCAR/GFDL) 2019JUL24
#   --- <Description>
#
# USAGE:
#   ---
#
# INPUT:
#   ---
#
# OUTPUT:
#   ---
#
# NOTES:
#   --- DriverScript args.
#       YMDH=$1      # Format: YYYYMMDDHH (e.g., 2019062000)
#       acct_name=$2
#       USRDEF_QOS=$3
#       njob_max=$4
#       runmode=$5
#
#    y) YMDH=${OPTARG};;
#    a) acct_name=${OPTARG};;
#    q) USRDEF_QOS=${OPTARG};;
#    m) runmode=${OPTARG};;
#    n) njob_max=${OPTARG};;
#    G) GRID=${OPTARG};;
#
# TODO:
#   ---
#
# UPDATES:
#   [2021SEP11] Copied from fv3_gfs_preproc.v201910; Adapted for 2021 T-SHiELD
#   [2021OCT12] Copied from Jet
#   [2021OCT19] ksh--->bash; Added njobs check
# =================================================

echo -e "\n==================== Starting run_retro.sh on $(hostname) at $(date) ====================\n"

setx=${setx:-'set +x'}
PS4='+ [$(date +"%H:%M:%S")] run_retro.sh line ${LINENO}: '
${setx}
set -ue

retro_cases='YMDHlist.log'
GRID='C768r10n4_atl_new' # C768r10n4_atl_new|C1536
#DriverScript='chgres_cube_driver.sh'
DriverScript='submit_vi_T-SHiELD.csh'
njob_max=40
rundir=${HOME}/NGGPS/VI/VI_scripts/scripts_for_rt_gaea_DEV

cd ${rundir} || exit 1

#for YMDH in $(cat ${retro_cases} | grep -v 'xxx')
#do
#  njobs=$(squeue -h -u ${USER} -t RUNNING,PENDING | wc -l)
#  if [ ${njobs} -ge ${njob_max} ]; then
#    set +x; echo -e "\nNot submitting additional jobs... njobs(${njobs})>=njob_max(${njob_max})\n"; ${setx}
#    exit 0
#  fi
#  ./${DriverScript} -y ${YMDH} -n ${njob_max} -G ${GRID} -F NO || exit 1 && sed -i "s/${YMDH}/xxx${YMDH}/g" ${retro_cases}
#done

for YMDH in $(cat ${retro_cases} | grep -v 'xxx')
do
  ./${DriverScript} ${YMDH} || exit 1 && sed -i "s/${YMDH}/xxx${YMDH}/g" ${retro_cases}
done

set +x; echo -e "\n==================== Ending run_retro.sh on $(hostname) at $(date) ====================\n"
