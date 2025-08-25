#!/bin/bash
# =================================================
# ${HOME}/NGGPS/VI/VI_scripts/scripts_for_rt_gaea/run_ncdiff.sh
#   --- Created by Matt Morin (UCAR/GFDL) 2019JUL24
#   --- <Description>
#
# USAGE:
#   ---
#
# INPUT:
#   ---
#
# NOTES:
#   --- cat ./vitals/syndat_tcvitals.2024 | awk '$1 ~ /^NHC/ {stormnum = substr($2, 1, 2) + 0; if (stormnum>=1 && stormnum<=49 && $13>=30) {print $4$5}}' | cut -c1-10 | sort -nu > YMDHlist.txt
#
# TODO:
#   ---
#
# UPDATES:
#   [2025AUG06] Adapted from run_retro.sh
# =================================================

echo -e "\n---------------------------------------------------------------------------------------------------------"
echo -e "vvvvvvvvvvvvvvvvvvvv STARTING run_ncdiff.sh on $(hostname) at $(date) vvvvvvvvvvvvvvvvvvvv"
echo -e "---------------------------------------------------------------------------------------------------------\n"

. ${MODULESHOME}/init/bash
module use -a /ncrc/home2/fms/local/modulefiles
module load fre/bronx-23

export setx=${setx:-'set +x'}
PS4='+ [$(date +"%H:%M:%S")] run_ncdiff.sh line ${LINENO}: '
${setx}
#set -e

datefile=YMDHlist.txt
rundir=${HOME}/NGGPS/VI/VI_scripts/scripts_for_rt_gaea
ICDirbase=/gpfs/f5/gfdl_w/proj-shared/${USER}/SHiELD_INPUT_DATA/global.v202311/C1536

cd ${rundir} || exit 1

for YMDH in $(cat ${datefile} | grep -v 'xxx' | sort -u)
do
  YMD=${YMDH:0:8}
  CYC=${YMDH:8:2}
  DATE="${YMD}.${CYC}Z"
  ICDir=${ICDirbase}/${DATE}_IC
  cd ${ICDir} || exit 1

  #echo "Running ncdiff for ${DATE}_IC"
  ##for icfile in $(/bin/ls -C1 gfs_data.tile?_vi_FIX2_?.nc)
  #for icfile in $(/bin/ls -C1 gfs_data.tile?_vi_?.nc)
  #do
  #  icfilebase=${icfile:0:14}
  #  if [ ! -f ${icfile}.diff ]; then
  #    exit 1         
  #    ncdiff ${icfile} ${icfilebase}.nc ${icfile}.diff || exit 1
  #  else
  #    echo "${icfile}.diff already exists! Exiting..."
  #    exit 1
  #  fi
  #done

  for icfile_old in $(/bin/ls -C1 gfs_data.tile?_vi_FIX3_?.nc)
  do
    icfile_new=$(echo ${icfile_old} | sed 's/vi_FIX3/vi/')
    if [ ! -f ${icfile_new} ]; then
      echo "ERROR: ${ICDir}/${icfile_new} does not exist! Exiting..."
      exit 1
    else
      echo "${DATE}_IC: nccmp -d ${icfile_new} ${icfile_old}"
      nccmp -d ${icfile_new} ${icfile_old} || echo "${DATE}" >> ${rundir}/rerun_F24V.log
    fi
  done

  sed -i "s/${YMDH}/xxx${YMDH}/g" ${rundir}/${datefile}

done # End of DATE loop

set +x
echo -e "\n---------------------------------------------------------------------------------------------------------"
echo "^^^^^^^^^^^^^^^^^^^^ ENDING run_ncdiff.sh on $(hostname) at $(date) ^^^^^^^^^^^^^^^^^^^^^^"
echo "---------------------------------------------------------------------------------------------------------"
