#!/bin/bash
# TODO --- Use this command instead (in basedir)
# find . -type f -name "*.out" -exec /home/Matthew.Morin/MJM_scripts/check_for_errors_in_stdout/check_for_actual_errors.sh {} \; | tee -a errors.log
# cat errors_SHiELD_rt2024.log | sort -u | egrep -v 'sacct: command not found'

# cat /work/${USER}/NGGPS/trakout/v20221214/SHiELD_rt2022/2022aGFSv16.err | awk -F: '{ $1=""; print}' | sed 's/^ //g' | egrep -v 'R34 issue: Adjusting ix_radii_end because it exceeds' | sort -u

PS4='+ find_errors_in_outdir.sh line ${LINENO}: '
#set -x

#THIS IS A WIP
exit         

# ++++++++++++++ START OF USER SETTINGS ++++++++++++++ #
CONFIGS=${1:-'2024b 2022aGFSv16'} # 2024b|2022aGFSv16|kt24d|kt23d|kt22d|kt21d
trkr_version=${2:-'v20250612'}    # v20250612|v20260305
#
#ignore_strings='genesis.vitals.SHiELD......20..: No such file or directory|genesis.vitals......20..: No such file or directory'
ignore_strings='sacct: command not found|failed for two consecutive|checking has failed for two|closed_mslp_ctr_flag2 FAIL|Fixed grid boundary alert|quad_wind_circ_flag FAIL|From sub getradii_2, there were|From sub get_wind_structure|1 in subroutine  bilin_int_uneven|routine after assigning missing wind value|jmax exceeded in subroutine|imax in subroutine|assigning missing wind value of -999'
#
rundir=${PWD}
ckerrs=${HOME}/MJM_scripts/check_for_errors_in_stdout/GFDL/check_for_actual_errors.sh
# ++++++++++++++ END   OF USER SETTINGS ++++++++++++++ #

for CONFIG_NAME in ${CONFIGS}; do
  source ${HOME}/NGGPS/do_pp/parm/set_vars.sh "${CONFIG_NAME}" || ( set +x; echo -e "\nERROR in set_vars.sh! Exiting...\n"; set -x; exit 1 )
  errlog=${rundir}/errors_${CONFIG_NAME}.log
  outdir=/work/${USER}/NGGPS/trakout/${trkr_version}/${RELEASE}
  cd ${outdir} || exit 1
  #for file in $(/bin/ls -C1 20??????.??Z.${NOTE}/*.out)
  for file in $(find ./20??????.??Z.${NOTE} -type f -name "*.out"); do
    ${ckerrs} '' ${file} | egrep -v "${ignore_strings}" | sort -u >> ${errlog}
    #${ckerrs} '' ${file} | sort -u >> ${errlog}
  done # End of file loop
done # End of CONFIG loop

sed -i '/^$/d' ${errlog}
ls -l ${errlog}
