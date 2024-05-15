#!/bin/tcsh 
module load intelpython/3.6.5
module load nco/4.9.3

# INPUT needed: CDATE
set CDATE = $1 

# === parameter settings

# vi criteria
set min_wind = 20.
set max_lat = 35.

# scripts
set vi_tool_dir = ${HOME}/NGGPS/hafs_tools/
set vi_driver_dir = ${HOME}/NGGPS/vi_driver/scripts_for_rt/
set vi_script = ${vi_driver_dir}/vi_T-SHiELD.sh

# vitals
set vital_base = ${vi_driver_dir}/tc_vitals # change to fs
set vital_dir_obs = ${vital_base}/observed_all/
set vital_dir_processed = ${vital_base}/processed/
set obs_vital = ${vital_dir_obs}/tcvitals_${CDATE}.txt # this is the obs vital at given time

echo $obs_vital

# ics
set DATE = `echo ${CDATE} | cut -c1-8`
set hh = `echo ${CDATE} | cut -c9-10`
set ic_base = /mnt/lfs1/HFIP/hfip-gfdl/${USER}/SHiELD_INPUT_DATA/variable.v202101/C768r10n4_atl_new/
set ic_dir = ${ic_base}/${DATE}.${hh}Z_IC/
set ic_src_file = ${ic_dir}/gfs_data.tile7.nc # IC without VI
set ic_dst_file = ${ic_dir}/gfs_data.tile7_vi_rt_test.nc # IC after VI

mkdir -p $vital_dir_obs
mkdir -p $vital_dir_processed

# === prepare text files for VI

# --- step 1: find if there is any ATL tc at the given time 

${vi_tool_dir}/ush/tcutil_multistorm_sort_jet_rt.py ${CDATE} L $min_wind $max_lat > tmpvit # select TCs
more tmpvit
grep -q -F "NHC" "tmpvit" && mv tmpvit ${obs_vital} || echo 'TC not found'
rm -f tmpvit

# --- step 2: if so, prepare the text files that can be used for VI 

# -d: date          -> current date as CDATE
# -w: min_wind      -> min Vmax for VI
# -l: max_lat       -> max initial lat for VI
# -i: ic_base       -> base dir for ic, e.g., '/lustre/f2/dev/gfdl/Kun.Gao/SHiELD_IC_v16/'+grid+'/'
# -f: vital_file    -> obs vital messages as a txt file, e.g., vital_base+'observed_all/tcvitals_'+date+'.txt'
# -o: vital_dir_out -> where processed tc txt files are saved, e.g., vital_base+'/processed/'

# addtional step on Jet: prepare ps.nc in netCDF3 for tracking
rm -rf ${ic_dir}/ps_nc3.nc
if ( ! -f ${ic_dir}/ps_nc3.nc) then
 ncks -C -v ps,geolon,geolat -3 ${ic_dir}/gfs_data.tile7.nc ${ic_dir}/ps_nc3.nc
endif

if ( -f ${obs_vital} && -f ${ic_src_file} ) then
   # note the wind and lat criteria are duplicated in script below
   ${vi_driver_dir}/prepare_tc_files.py -d ${CDATE} -w $min_wind -l $max_lat -i $ic_base -f $obs_vital -o $vital_dir_processed
endif

rm -rf ${ic_dir}/ps_nc3.nc

# === trigger VI script

if (-f ${vital_dir_processed}/${CDATE}/tcvitals.vi ) then

     # safety check?
     if ( ! -f $ic_dst_file ) then
       set atcf_file = `cd ${vital_dir_processed}/${CDATE} && ls *atcf*`
       set STORMID=`echo $atcf_file  | cut -c1-3`
       echo 'submitting' $CDATE, $STORMID

       # the VI script should trigger T-SHiELD forecast    
       sbatch --job-name=vi_ic_${CDATE} --export=CDATE=${CDATE},STORMID=${STORMID},ALL ${vi_script}
     endif

# if VI not triggered, trigger forecast job from here
else
    # submit the forecast job
    echo 'No need for VI; submitting forecast job for' $CDATE
    runscript=${HOME}/NGGPS/T-SHiELD_rt2023/SHiELD_run/JETrt/submit_forecast.sh
    runmode='realtime'
    ${runscript} -y "${CDATE}" -m "${runmode}"
endif
