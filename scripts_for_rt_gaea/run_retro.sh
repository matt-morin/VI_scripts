#!/bin/bash
# =================================================
# ${HOME}/NGGPS/VI/VI_scripts/scripts_for_rt_gaea/run_retro.sh
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
#   [2025JUN10] Adapted from ~/NGGPS/SHiELD_rt2024/SHiELD_run/GAEA/
#   [2025AUG22] Added functionality for running VI tests safely
# =================================================

echo -e "\n---------------------------------------------------------------------------------------------------------"
echo -e "vvvvvvvvvvvvvvvvvvvv STARTING run_retro.sh on $(hostname) at $(date) vvvvvvvvvvvvvvvvvvvv"
echo -e "---------------------------------------------------------------------------------------------------------\n"

export setx=${setx:-'set +x'}
PS4='+ [$(date +"%H:%M:%S")] run_retro.sh line ${LINENO}: '
${setx}
#set -e

modelname='T-SHiELD' #SHiELD|T-SHiELD
export run_fcst='NO' #YES|NO
export min_wind=20   #TODO: For "VItest01"    
VIlabel='VItest01'   #TODO: For "VItest01"    
do_PART1='NO'        #YES|NO
do_PART2='YES'
do_PART3='YES'
#
rundir=${HOME}/NGGPS/VI/VI_scripts/scripts_for_rt_gaea
case ${modelname} in
  SHiELD) tcvitDir=tc_vitals/SHiELD
          ICDirbase=/gpfs/f5/gfdl_w/proj-shared/${USER}/SHiELD_INPUT_DATA/global.v202311/C1536
          ICfile=gfs_data.tile6.nc;;
  T-SHiELD) tcvitDir=tc_vitals
            ICDirbase=/gpfs/f5/gfdl_w/proj-shared/${USER}/SHiELD_INPUT_DATA/variable.v202311/C768r10n4_atl_new
            ICfile=gfs_data.tile7.nc;;
esac
datefile=${rundir}/YMDHlist.txt
ICsNeeded=${rundir}/ICsNeeded.log
njob_max=200
njobs=$(squeue -h -u ${USER} -o '%10i %90j %12r' -t RUNNING,PENDING | grep -v 'JobHeldUser' | grep -c 'vi_ic_')

cd ${rundir} || exit 1

for YMDH in $(cat ${datefile} | grep -v 'xxx' | sort -u)
do

  if [ ${njobs} -ge ${njob_max} ]; then
    set +x; echo -e "\nNOTE: njobs (${njobs}) >= njob_max (${njob_max}). Breaking out of loop..."; ${setx}
    break
  fi

  YMD=${YMDH:0:8}
  CYC=${YMDH:8:2}
  DATE="${YMD}.${CYC}Z"
  ICDir=${ICDirbase}/${DATE}_IC
  stdout=${ICDir}/submit_vi_${modelname}.out

  if [ ${do_PART1} == 'YES' ]; then
    # PART1: Running submit_vi_${modelname}.csh
    if [ ! -f ${ICDir}/${ICfile} ]; then
      echo "ALERT: No ICs for ${DATE}"
      echo "${YMDH}" >> ${ICsNeeded}
    else
      if [ -f ${stdout} ]; then
        echo "ERROR: ${stdout} already exists! Exiting..."
        exit 1
      else
        echo "Running submit_vi_${modelname}.csh for ${YMDH}"
        ./submit_vi_${modelname}.csh ${YMDH} > ${stdout} 2>&1
        ((njobs=njobs+1))
        sleep 2
      fi
    fi
  fi

  if [ ${do_PART2} == 'YES' ]; then
    # PART2: Archiving/moving the tc_vitals data (for abnormal VI tests)
    cd ${rundir}
    echo "mv ${tcvitDir}/observed_all/tcvitals_${YMDH}.txt ${tcvitDir}/observed_all/tcvitals_${YMDH}_${VIlabel}.txt"
    mv ${tcvitDir}/observed_all/tcvitals_${YMDH}.txt ${tcvitDir}/observed_all/tcvitals_${YMDH}_${VIlabel}.txt
    echo "mv ${tcvitDir}/processed/${YMDH} ${tcvitDir}/processed/${YMDH}_${VIlabel}"
    mv ${tcvitDir}/processed/${YMDH} ${tcvitDir}/processed/${YMDH}_${VIlabel}
  fi

  if [ ${do_PART3} == 'YES' ]; then
    # PART3: Rename the "vi" output using ${VIlabel}
    cd ${ICDir} || exit 1
    for vifile in $(find . -maxdepth 1 -type f -name "*vi*" -mtime -1)
    do
      echo "rename vi ${VIlabel} ${vifile}"
      rename vi ${VIlabel} ${vifile}
    done
  fi

  sed -i "s/${YMDH}/xxx${YMDH}/g" ${datefile}

done # End of DATE loop

set +x
echo -e "\n---------------------------------------------------------------------------------------------------------"
echo "^^^^^^^^^^^^^^^^^^^^ ENDING run_retro.sh on $(hostname) at $(date) ^^^^^^^^^^^^^^^^^^^^^^"
echo "---------------------------------------------------------------------------------------------------------"
