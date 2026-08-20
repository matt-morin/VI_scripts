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
#   --- YMDHlist.txt
#
# NOTES:
#   --- cat ./vitals/syndat_tcvitals.2024 | awk '$1 ~ /^NHC/ {stormnum = substr($2, 1, 2) + 0; if (stormnum>=1 && stormnum<=49 && $13>=30) {print $4$5}}' | cut -c1-10 | sort -nu > YMDHlist.txt
#   --- Rerunning VI ICs
#       [In C1536 dir] rename vi viORIG {20250816.06Z,20240817.06Z,20240701.12Z,20241004.18Z,20241010.00Z,20241009.18Z,20240827.06Z,20241004.12Z}_IC/{gfs_data.tile?_vi_?.nc.diff,vi_ic_C1536_20????????.out,gfs_data.tile?_vi_?.nc,submit_vi_SHiELD.out}
#       [In tc_vitals processed dir] foreach Dir ( 2025081606 2024081706 2024070112 2024100418 2024101000 2024100918 2024082706 2024100412 ); mv $Dir ${Dir}_ORIG; end
#       [In tc_vitals observed_all dir] rename .txt .txt_ORIG tcvitals_{2025081606,2024081706,2024070112,2024100418,2024101000,2024100918,2024082706,2024100412}.txt
#
# TODO:
#   --- Rethink the order of the "do_PART" sections so I can easily do rerun tests
#
# UPDATES:
#   [2025JUN10] Adapted from ~/NGGPS/SHiELD_rt2024/SHiELD_run/GAEA/
#   [2025AUG22] Added functionality for running VI tests safely
#   [2026MAY19] Cosmetic mods.; Added notes
#   [2026JUN05] Added T-SHiELD_new; Normal runtime mods.
# =================================================

echo "---------------------------------------------------------------------------------------------------------"
echo "----- STARTING run_retro.sh on $(hostname) at $(date)"
echo "---------------------------------------------------------------------------------------------------------"

export setx=${setx:-'set +x'}
PS4='+ [$(date +"%H:%M:%S")] run_retro.sh line ${LINENO}: '
${setx}

# ++++++++++++++ START OF MAIN USER SETTINGS +++++++++++++++ #
modelname='SHiELD'    #SHiELD|T-SHiELD|T-SHiELD_new
export run_fcst='NO'  #YES|NO
#export min_wind=20   #For "VItest01"
#VIlabel='RERUN'      #VItest01|RERUN
do_PART1='YES'        #YES|NO (Running submit_vi_${modelname}.csh)
do_PART2='NO'         #YES|NO (Archiving/moving the tc_vitals data (for abnormal VI tests)) #TODO: Needs improvement (out of order)
do_PART3='NO'         #YES|NO (Rename the "vi" output using ${VIlabel})                     #TODO: Needs improvement (out of order)
# ++++++++++++++  END  OF MAIN USER SETTINGS +++++++++++++++ #

# ++++++++++++++ START OF OTHER USER SETTINGS ++++++++++++++ #
rundir=${HOME}/NGGPS/VI/VI_scripts/scripts_for_rt_gaea
case ${modelname} in
  SHiELD) ICDirbase=/gpfs/f5/gfdl_w/proj-shared/${USER}/SHiELD_INPUT_DATA/global.v202311/C1536
          ICfile=gfs_data.tile6.nc;;
  T-SHiELD) ICDirbase=/gpfs/f5/gfdl_w/proj-shared/${USER}/SHiELD_INPUT_DATA/variable.v202311/C768r10n4_atl_new
            ICfile=gfs_data.tile7.nc;;
  T-SHiELD_new) ICDirbase=/gpfs/f5/gfdl_w/proj-shared/${USER}/SHiELD_INPUT_DATA/variable.v202311/C768r10n5_atl_large
            ICfile=gfs_data.tile7.nc;;
esac
tcvitDir=tc_vitals/${modelname}
datefile=${rundir}/YMDHlist.txt
ICsNeeded=${rundir}/ICsNeeded.log
njob_max=200
njobs=$(squeue -h -u ${USER} -o '%10i %90j %12r' -t RUNNING,PENDING | grep -v 'JobHeldUser' | grep -c 'vi_ic_')
# ++++++++++++++  END  OF OTHER USER SETTINGS ++++++++++++++ #

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
  workDir=/gpfs/f5/gfdl_w/scratch/Matthew.Morin/vi_work/${modelname}/${YMDH}
  ICDir=${ICDirbase}/${DATE}_IC
  stdout=${ICDir}/submit_vi_${modelname}.out
  tcvitals1=${tcvitDir}/observed_all/tcvitals_${YMDH}.txt
  tcvitals2=${tcvitDir}/processed/${YMDH}

  if [ ${do_PART1} == 'YES' ]; then
    # PART1: Running submit_vi_${modelname}.csh
    if [ -d ${workDir} ]; then
      echo "WARNING: ${workDir} already exists! Move or remove before proceeding. Exiting..."
      exit 1
    fi
    if [ -f ${tcvitals1} -o -d ${tcvitals2} ]; then
      echo "WARNING: ${tcvitals1} and/or ${tcvitals2} already exists! Move or remove before proceeding. Exiting..."
      exit 1
    fi
    if [ ! -f ${ICDir}/${ICfile} ]; then
      echo "ALERT: No ICs for ${DATE}"
      echo "${YMDH}" >> ${ICsNeeded}
    else
      if [ -f ${stdout} ]; then
        echo "NOTE: ${stdout} already exists! Moving on to next case..."
        sed -i "s/${YMDH}/xxxXXX${YMDH}/g" ${datefile}
        continue
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
    echo "mv ${tcvitDir}/processed/${YMDH} ${tcvitDir}/processed/${YMDH}_${VIlabel}"
    mv ${tcvitDir}/observed_all/tcvitals_${YMDH}.txt ${tcvitDir}/observed_all/tcvitals_${YMDH}_${VIlabel}.txt || exit 1
    mv ${tcvitDir}/processed/${YMDH} ${tcvitDir}/processed/${YMDH}_${VIlabel} || exit 1
  fi

  if [ ${do_PART3} == 'YES' ]; then
    # PART3: Rename the "vi" output using ${VIlabel}
    cd ${ICDir} || exit 1
    for vifile in $(find . -maxdepth 1 -type f -name "*vi_*" -mtime -1)
    do
      echo "rename vi ${VIlabel} ${vifile}"
      rename vi ${VIlabel} ${vifile} || exit 1
    done
  fi

  sed -i "s/${YMDH}/xxx${YMDH}/g" ${datefile}

done # End of DATE loop

set +x
echo "---------------------------------------------------------------------------------------------------------"
echo "----- ENDING   run_retro.sh on $(hostname) at $(date)"
echo "---------------------------------------------------------------------------------------------------------"
