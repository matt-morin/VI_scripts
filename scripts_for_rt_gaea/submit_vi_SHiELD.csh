#!/bin/tcsh
# =================================================
# ${HOME}/NGGPS/VI/VI_scripts/scripts_for_rt_gaea/submit_vi_SHiELD.csh
#   --- Created by Kun Gao and maintained by Matt Morin (UCAR/GFDL)
#   --- This script drives the VI-related workflow for the RT SHiELD
#       It is triggerd by the IC creation script once ICs are generated
#       If there are storms that need VI, this script will:
#        - create two TC text files to be used by VI
#        - launch the VI script
#
# USAGE:
#   --- ./submit_vi_SHiELD.csh ${YMDH}
#   --- Can be launched using ./run_retro.sh
#
# INPUT:
#   --- /gpfs/f5/gfdl_w/scratch/Matthew.Morin/NGGPS/vitals/syndat_tcvitals.${YYYY}
#       ${ic_base}/gfs_data.tile[1-6].nc
#
# OUTPUT:
#   --- tc_vitals/SHiELD/observed_all/tcvitals_${YMDH}.txt
#       tc_vitals/SHiELD/processed/${YMDH}/${STORMID}_tile${ic_tile}/tcvitals.vi
#       tc_vitals/SHiELD/processed/${YMDH}/${STORMID}_tile${ic_tile}/${STORMID}.${YMDH}.trak.atcfunix.all
#       ${ic_base}/gfs_data.tile[1-6]_vi_?.nc
#
# NOTES:
#   ---
#
# TODO:
#   --- max_lat=40 --- Is this number OK for all TC basins (was 35)?
#
# UPDATES:
#   [2025MAR17] Added documentation header; Added notify_error function
#   [2025MAR21] Better handled missing tmpvit file
#   [2025MAY15] Adapted from submit_vi_T-SHiELD.csh
#   [2025JUN04] Moved active tmpvit to $tempdir; Looping tcutil_multistorm_sort_gfdl.py within $BASINID_list; Increased max_lat from 35 to 40; Cosmetic mods.
#   [2025JUN09] Finished development looping over $ic_tile_list
#   [2025AUG22] Added use of $run_fcst
#   [2025SEP09] Cosmetic mods.
#   [2026MAY19] Cosmetic and STDO mods. (synced with T-SHiELD)
#   [2026AUG20] Synced with submit_vi_T-SHiELD_new.csh; Removed trailing forward slash from path definitions
# =================================================

echo "-----------------------------------------------------------------------------------------------------------"
echo "----- STARTING submit_vi_SHiELD.csh on `hostname` at `date`"
echo "-----------------------------------------------------------------------------------------------------------"

# Define an alias that sends all given arguments ($!:*) as the error message
alias notify_error 'echo "\!:*" | mail -s "Error in submit_vi_SHiELD.csh" matthew.morin@noaa.gov'

module load python/3.9

set echo
set verbose
unlimit

# === get the model initialization date&time from command-line argument
set CDATE = $1

#if (! $?SLURM_JOB_QOS) then #[2026AUG25] TODO: Re-enable when needed
  setenv USRDEF_QOS 'normal'
#else
#  setenv USRDEF_QOS $SLURM_JOB_QOS
#endif
if (! $?run_fcst) then
  setenv run_fcst 'YES'
else
  setenv run_fcst ${run_fcst}
endif

# === directory to be specified by the user

set tempdir = `mktemp -d`

# vi code and scripts
set vi_base = ${HOME}/NGGPS/VI
cd ${vi_base} || exit 1

# TC criteria
set BASINID_list = 'L E' # MJM --- 'L E C W S P A B'

# ic files
set GRID = 'C1536'
set ic_base = /gpfs/f5/gfdl_w/proj-shared/${USER}/SHiELD_INPUT_DATA/global.v202311/${GRID}
set ic_tile_list = '1 5' # MJM --- Tiles 1 and 5 have been tested with this system

# vi criteria (will be passed to python scripts that generated TC files)
#set min_wind = 30.
if (! $?min_wind) set min_wind = 30.
set max_lat = 40. # MJM TODO --- Is this number OK for all TC basins (was 35)?

# === specific dir and file name settings

# scripts
set vi_tool_dir = ${vi_base}/HAFS_tools
set vi_driver_dir = ${vi_base}/VI_scripts/scripts_for_rt_gaea
set vi_script = ${vi_driver_dir}/vi_SHiELD.sh

# tc files
set vital_base = ${vi_driver_dir}/tc_vitals/SHiELD
set vital_dir_obs = ${vital_base}/observed_all
set vital_dir_processed = ${vital_base}/processed
set obs_vital = ${vital_dir_obs}/tcvitals_${CDATE}.txt # this is the obs vital at given time
set tmpvit = ${tempdir}/tmpvit

# ics
set DATE = `echo ${CDATE} | cut -c1-8`
set hh = `echo ${CDATE} | cut -c9-10`
set ic_dir = ${ic_base}/${DATE}.${hh}Z_IC

mkdir -p $vital_dir_obs
mkdir -p $vital_dir_processed

# === Step 1: prepare text files for VI
# this step will generate the two text files used by VI

echo "VILOG: min_wind=${min_wind}"
echo "VILOG: max_lat=${max_lat}"

set nonomatch vitfiles=(${vital_dir_processed}/${CDATE}/???_tile?/tcvitals.vi)
if ( ! -e $vitfiles[1] ) then

  # --- Loop tcutil_multistorm_sort through the list of basins to find initially-qualifying TCs (output=${obs_vital})

  rm -f ${tmpvit} # MJM safety measure
  foreach BASINID ( ${BASINID_list} ) # MJM
    ${vi_tool_dir}/ush/tcutil_multistorm_sort_gfdl.py ${CDATE} ${BASINID} $min_wind $max_lat >> ${tmpvit} # Selected TCs
    if ( ${status} != 0 ) then # MJM
      notify_error "Error in tcutil_multistorm_sort_gfdl.py for ${CDATE} ${BASINID}"
    endif
  end # MJM

  if ( ! -z ${tmpvit} ) then
    more ${tmpvit}
    grep -q -F "NHC" "${tmpvit}" && mv ${tmpvit} ${obs_vital} || echo 'VILOG: TC not found'
    rm -f ${tmpvit}
  else
    echo 'VILOG: TC not found'
  endif

  # --- if so, prepare the text files that can be used for VI (using prepare_tc_files_SHiELD.py)

  # -d: date          -> current date as CDATE
  # -w: min_wind      -> min Vmax for VI
  # -l: max_lat       -> max initial lat for VI
  # -i: ic_base       -> base dir for ic, e.g., '/lustre/f2/dev/gfdl/Kun.Gao/SHiELD_IC_v16/'+grid
  # -f: vital_file    -> obs vital messages as a txt file, e.g., vital_base+'observed_all/tcvitals_'+date+'.txt'
  # -o: vital_dir_out -> where processed tc txt files are saved, e.g., vital_base+'/processed'
  # -t: ic_tile       -> tile number for ic, e.g., 1

  foreach ic_tile ( ${ic_tile_list}  ) # MJM
    set ic_src_file = ${ic_dir}/gfs_data.tile${ic_tile}.nc                # IC without VI
    set nonomatch ic_dst_file=(${ic_dir}/gfs_data.tile${ic_tile}_vi_?.nc) # IC after VI
    if ( -f ${obs_vital} && -f ${ic_src_file} ) then
      # note the wind and lat criteria are duplicated in script below
      echo "VILOG (tile${ic_tile}): prepare_tc_files_SHiELD.py -d ${CDATE} -w $min_wind -l $max_lat -i $ic_base -f $obs_vital -o $vital_dir_processed -t $ic_tile"
      ${vi_driver_dir}/prepare_tc_files_SHiELD.py -d ${CDATE} -w $min_wind -l $max_lat -i $ic_base -f $obs_vital -o $vital_dir_processed -t $ic_tile
      if ( ${status} != 0 ) then # MJM
        notify_error "Error in prepare_tc_files_SHiELD.py for ${CDATE} tile${ic_tile}"
      endif
    else
      echo "VILOG (tile${ic_tile}): Not calling ${vi_driver_dir}/prepare_tc_files_SHiELD.py [obs_vital(${obs_vital}) and/or ic_src_file(${ic_src_file}) not available]"
    endif
  end # MJM

endif

# === Step 2. trigger VI script

# tcvitals.vi can be used as a flag; if it exists for a given date&time, VI is needed for this case
set nonomatch vitfiles=(${vital_dir_processed}/${CDATE}/???_tile?/tcvitals.vi)
if ( -e $vitfiles[1] ) then

  set VITASKlist = `/bin/ls -C1 ${vitfiles} | awk -F/ '{print $(NF-1)}' | tr '\n' ' '`
  set nonomatch ic_dst_file=(${ic_dir}/gfs_data.tile?_vi_?.nc) # IC after VI
  if ( ! -e $ic_dst_file[1] ) then
    echo "VILOG: Submitting ${CDATE} for ${VITASKlist}"
    set JOB_NAME = vi_ic_${GRID}_${CDATE}
    sbatch --job-name=${JOB_NAME} --output=${ic_dir}/%x.out --export=NONE,CDATE=${CDATE},VITASKlist="${VITASKlist}",run_fcst=${run_fcst} --qos ${USRDEF_QOS} ${vi_script}
    if ( ${status} != 0 ) then
      notify_error "Error launching ${JOB_NAME} batch job"
      exit 1
    endif
  else
    notify_error "Error: ${JOB_NAME} not launched because $ic_dst_file[1] is already available"
    continue
  endif

#else # if VI not triggered, trigger forecast job from here
#
#  if ( "${run_fcst}" == 'YES' ) then
#    # submit the forecast job
#    echo 'VILOG: No need for VI; Submitting forecast job for' ${CDATE}
#    set runscript = ${HOME}/NGGPS/SHiELD_rt2024/SHiELD_run/GAEA/submit_forecast.sh
#    set runmode = 'realtime'
#    ${runscript} -y "${CDATE}" -a 'gfdl_w' -m "${runmode}" -n 999
#  endif

endif

unset echo verbose
echo "-----------------------------------------------------------------------------------------------------------"
echo "----- ENDING   submit_vi_SHiELD.csh on `hostname` at `date`"
echo "-----------------------------------------------------------------------------------------------------------"
