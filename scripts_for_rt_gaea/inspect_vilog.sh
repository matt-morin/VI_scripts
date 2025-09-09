#!/bin/bash
# ./inspect_vilog.sh | awk '{ print $NF,$0 }' | sort -k1,1 -n | cut -f2- -d' '
# cklessmult 2025*IC/*vi*.out

#set -x
set -e

index_min=1    #18 12 28 40
index_max=30   #12 30 35 60 1000
#
YYYY=2025
CONFIG_NAME='2024bVI'

rundir=${HOME}/NGGPS/VI/VI_scripts/scripts_for_rt_gaea
vitdir=/gpfs/f5/gfdl_w/scratch/${USER}/NGGPS/vitals
ICdir=/gpfs/f5/gfdl_w/proj-shared/Matthew.Morin/SHiELD_INPUT_DATA/global.v202311/C1536
YMDHlist=${rundir}/YMDHlist_diff.txt
tcvit=${HOME}/bin/tcvit_date

# ========================================================================================= #
cd ${ICdir} || exit 1
#for DATE in 20240629.18Z 20240701.12Z 20240817.00Z 20240817.06Z 20240827.06Z 20240927.06Z 20241004.12Z 20241004.18Z 20241009.12Z 20241009.18Z 20241010.00Z
#do
  for vilog in ${YYYY}????.??Z_IC/{submit_vi_SHiELD.out,submit_vi_FIX3_SHiELD.out} #*FIX2*.out #*vi*.out
  #for vilog in ${DATE}_IC/submit_vi_SHiELD.out #*FIX2*.out #*vi*.out
  do
    # Step 1: Extract vilogstr from the current vilog
    vilogstr=$(grep 'find_good_tc =  True' "$vilog" | awk -F: '{print $1}')
    #echo "vilogstr=${vilogstr}"
    # Only proceed if we found a string
    if [[ -n "$vilogstr" ]]; then
      # Step 2 & 3: Search for vilogstr in this vilog and filter with awk
      grep "${vilogstr}" ${vilog} /dev/null | grep 'min(de.,dw.,ds.,dn.)' | awk '{if ($NF>='${index_min}' && $NF<'${index_max}') print $0}'
    fi
  done # End of vilog loop
#done # End of DATE loop
# ========================================================================================= #

## ========================================================================================= #
## USAGE: ./inspect_vilog.sh > NonQualifyingVICases_${YYYY}_${CONFIG_NAME}.log
#cd ${rundir}
#cat ${vitdir}/syndat_tcvitals.${YYYY} | awk '$1 ~ /^NHC/ {stormnum = substr($2, 1, 2) + 0; if (stormnum>=1 && stormnum<=49 && $13>=30) {print $4$5}}' | cut -c1-10 | sort -nu > YMDHlist.txt
#/bin/ls -C1 ${ICdir}/${YYYY}*IC/*vi_?.nc | awk -F/ '{print $(NF-1)}' | sort -u | cut -c1-11 | sed 's/\.//g' > YMDHlist_compare.txt
#diff YMDHlist_compare.txt YMDHlist.txt | grep '>' | awk '{print $2}' > YMDHlist_diff.txt
#echo "$(cat YMDHlist_diff.txt | wc -l) non-qualifying VI IC cases for ${CONFIG_NAME}"
#cd ${ICdir}
#for YMDH in $(cat ${rundir}/YMDHlist_diff.txt)
#do
#  YMD=${YMDH:0:8}
#  CYC=${YMDH:8:2}
#  DATE="${YMD}.${CYC}Z"
#  ${tcvit} ${YMDH} | grep 'NHC' | awk '{if ($13>=30) {print $0}}'
#  grep "^VILOG" ${DATE}_IC/submit_vi_SHiELD.out
#  echo " "
#done
## ========================================================================================= #
