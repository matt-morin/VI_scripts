#!/bin/bash
# =================================================
# ${HOME}/NGGPS/VI/VI_scripts/scripts_for_rt_gaea/run_reruns.sh
#   --- Created by Matt Morin (UCAR/GFDL) 2026JUN02
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
#   --- It'd be nice to rename viORIG_ back to vi_ when finished (or do I already have an option to run submit_vi_*SHiELD.csh with an optional VIlabel?)
#   --- Finish the WIP block of code
#
# UPDATES:
#   [2026JUN02] Adapted from run_retro.sh
# =================================================

echo "---------------------------------------------------------------------------------------------------------"
echo "----- STARTING run_reruns.sh on $(hostname) at $(date)"
echo "---------------------------------------------------------------------------------------------------------"

export setx=${setx:-'set +x'}
PS4='+ [$(date +"%H:%M:%S")] run_reruns.sh line ${LINENO}: '
${setx}

# ++++++++++++++ START OF MAIN USER SETTINGS +++++++++++++++ #
modelname='SHiELD'    #SHiELD|T-SHiELD
export run_fcst='NO'  #YES|NO
VIlabel='ORIG'        #ORIG
#
rundir=${HOME}/NGGPS/VI/VI_scripts/scripts_for_rt_gaea
#datefile=${rundir}/YMDHlist.txt  # Comment out if specifying YMDHlist as $1 (arg. 1)
if [ -z "${datefile}" ]; then
  YMDHlist="$1"
else
  YMDHlist="$(cat ${datefile} | grep -v 'xxx' | sort -u)"
fi
# ++++++++++++++  END  OF MAIN USER SETTINGS +++++++++++++++ #

# ++++++++++++++ START OF OTHER USER SETTINGS ++++++++++++++ #
case ${modelname} in
  SHiELD) GRID='C1536'
          ICDirbase=/gpfs/f5/gfdl_w/proj-shared/${USER}/SHiELD_INPUT_DATA/global.v202311/${GRID}
          ICfile=gfs_data.tile6.nc;;
  T-SHiELD) GRID='C768r10n4_atl_new'
            ICDirbase=/gpfs/f5/gfdl_w/proj-shared/${USER}/SHiELD_INPUT_DATA/variable.v202311/${GRID}
            ICfile=gfs_data.tile7.nc;;
esac
tcvitDir=tc_vitals/${modelname}
ICsNeeded=${rundir}/ICsNeeded.log
njob_max=200
njobs=$(squeue -h -u ${USER} -o '%10i %90j %12r' -t RUNNING,PENDING | grep -v 'JobHeldUser' | grep -c 'vi_ic_')
# ++++++++++++++  END  OF OTHER USER SETTINGS ++++++++++++++ #

set +x
for var in modelname run_fcst ICDirbase ICfile tcvitDir njob_max njobs YMDHlist
do
  if [ -n "${!var:-}" ] ; then
    echo "${var} is set to ${!var}"
  else
    echo "ERROR: ${var} is not set! Exiting..."; set -x
    exit 1
  fi
done
${setx}

cd ${rundir} || exit 1

for YMDH in ${YMDHlist}
do

  if [ ${njobs} -ge ${njob_max} ]; then
    set +x; echo "NOTE: njobs (${njobs}) >= njob_max (${njob_max}). Breaking out of loop..."; ${setx}
    break
  fi
  if ! date -d "${YMDH:0:8} ${YMDH:8:2}" >/dev/null 2>&1; then
    set +x; echo -e "\nERROR: YMDH (${YMDH}) isn't in the expected form. Exiting...\n"; set -x
    exit 1
  fi

  YMD=${YMDH:0:8}
  CYC=${YMDH:8:2}
  DATE="${YMD}.${CYC}Z"
  ICDir=${ICDirbase}/${DATE}_IC
  stdout=${ICDir}/submit_vi_${modelname}.out

  if [ ! -f ${ICDir}/${ICfile} ]; then
    echo "ALERT: No ICs for ${DATE}! Moving on to next case..."
    echo "${YMDH}" >> ${ICsNeeded}
    if [ ! -z "${datefile}" ]; then
      sed -i "s/${YMDH}/xxx${YMDH}/g" ${datefile}
    fi
    continue
  fi

  # STEP1: Preserve the original "*vi_*" files
  cd ${ICDir} || exit 1
  shopt -s nullglob
  #for vifile in $(find . -maxdepth 1 -type f -name "*vi_*"); do
  for vifile in *vi_*; do
    [[ -f "$vifile" ]] || exit 1 # Exit if you come across a non-regular file
    target="${vifile/vi_/vi${VIlabel}_}"
    if [[ -e "${target}" ]]; then
      echo "WARNING: Rename would overwrite '$target'. Aborting." >&2
      exit 1
    fi
    rename -v --no-overwrite vi_ "vi${VIlabel}_" "${vifile}" || exit 1
  done

  # STEP2: Preserve the original tc_vitals data
  cd ${rundir}
  #mv -v --no-clobber ${tcvitDir}/observed_all/tcvitals_${YMDH}.txt ${tcvitDir}/observed_all/tcvitals_${YMDH}_${VIlabel}.txt || exit 1
  #mv -v --no-clobber ${tcvitDir}/processed/${YMDH} ${tcvitDir}/processed/${YMDH}_${VIlabel} || exit 1
  s1="${tcvitDir}/observed_all/tcvitals_${YMDH}.txt"; t1="${tcvitDir}/observed_all/tcvitals_${YMDH}_${VIlabel}.txt"
  [[ -e "$s1" ]] && { [[ -e "$t1" ]] && exit 1; mv -v "$s1" "$t1"; }
  s2="${tcvitDir}/processed/${YMDH}"; t2="${tcvitDir}/processed/${YMDH}_${VIlabel}"
  [[ -e "$s2" ]] && { [[ -e "$t2" ]] && exit 1; mv -v "$s2" "$t2"; }

  # STEP3: Run submit_vi_${modelname}.csh
  echo "Running submit_vi_${modelname}.csh for ${YMDH}"
  ./submit_vi_${modelname}.csh ${YMDH} > ${stdout} 2>&1
  ((njobs=njobs+1))
  sleep 2

  if [ ! -z "${datefile}" ]; then
    sed -i "s/${YMDH}/xxx${YMDH}/g" ${datefile}
  fi

done # End of DATE loop

#***WIP: Check the output for issues/repro ***#
#   diff tc_vitals/T-SHiELD/processed/2025102600/13L/tcvitals.vi tc_vitals/T-SHiELD/processed/2025102600_ORIG/13L/
#   diff tc_vitals/T-SHiELD/processed/2025102600/13L/13L.2025102600.trak.atcfunix.all tc_vitals/T-SHiELD/processed/2025102600_ORIG/13L/
#   diff tc_vitals/T-SHiELD/observed_all/tcvitals_2025102600.txt tc_vitals/T-SHiELD/observed_all/tcvitals_2025102600_ORIG.txt
#   cd /gpfs/f5/gfdl_w/proj-shared/Matthew.Morin/SHiELD_INPUT_DATA/variable.v202311/C768r10n4_atl_new/20251026.00Z_IC/
#   ckless
#   nccmp -d gfs_data.tile7_vi_1.nc gfs_data.tile7_viORIG_1.nc
#   ANSWERS MATCH!
#   rm -f gfs_data.tile7_vi_1.nc
#   mv gfs_data.tile7_viORIG_1.nc gfs_data.tile7_vi_1.nc
#   mv vi_ic_C768r10n4_atl_new_2025102600.out viRERUN_ic_C768r10n4_atl_new_2025102600.out
#   mv viORIG_ic_C768r10n4_atl_new_2025102600.out vi_ic_C768r10n4_atl_new_2025102600.out
#********************************************#

set +x
echo "---------------------------------------------------------------------------------------------------------"
echo "----- ENDING   run_reruns.sh on $(hostname) at $(date)"
echo "---------------------------------------------------------------------------------------------------------"
