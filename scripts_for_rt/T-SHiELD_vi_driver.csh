#!/bin/tcsh 

# INPUT needed: CDATE
set CDATE = 2022092000

# === parameter settings
set DATE = `echo ${CDATE} | cut -c1-8`
set hh = `echo ${CDATE} | cut -c9-10`

set vi_script = /ncrc/home1/Kun.Gao/vi_driver/scripts_for_rt/vi_T-SHiELD.sh

set min_wind = 20.
set max_lat = 35.

set vital_base = /ncrc/home1/Kun.Gao/vi_driver/scripts_for_rt/tc_vitals
set vital_dir_obs = ${vital_base}/observed_all/
set vital_dir_processed = ${vital_base}/processed/

set ic_dir = /lustre/f2/dev/gfdl/Kun.Gao/SHiELD_IC_v16/C768r10n4_atl_new/

set obs_vital = ${vital_dir_obs}/tcvitals_${CDATE}.txt
set ic_src_file = ${ic_dir}/${DATE}.${hh}Z_IC/gfs_data.tile7.nc
set ic_dst_file = ${ic_dir}/${DATE}.${hh}Z_IC/gfs_data.tile7_vi_rt_test.nc

mkdir -p $vital_dir_obs
mkdir -p $vital_dir_processed

# === preparing text files for VI

# --- step 1: find if there is any ATL tc at the given time 

# note some loose criteria already added here
# TODO: make a new version of tcutil_multistorm_sort for RT (use very small min_wind and large max_lat)
/ncrc/home1/Kun.Gao/hafs_tools/ush/tcutil_multistorm_sort_kgao.py ${DATE}${hh} L $min_wind $max_lat > tmpvit
more tmpvit
# !!! change cp to mv
grep -q -F "NHC" "tmpvit" && cp tmpvit ${obs_vital} || echo 'TC not found'
#rm -f tmpvit

# --- step 2: if so, prepare the text files that can be used for VI 

# -d: date          -> current date as CDATE
# -w: min_wind      -> min Vmax for VI
# -l: max_lat       -> max initial lat for VI
# -i: ic_base       -> base dir for ic, e.g., '/lustre/f2/dev/gfdl/Kun.Gao/SHiELD_IC_v16/'+grid+'/'
# -f: vital_file    -> obs vital messages as a txt file, e.g., vital_base+'observed_all/tcvitals_'+date+'.txt'
# -o: vital_dir_out -> where processed tc txt files are saved, e.g., vital_base+'/processed/'

if ( -f ${obs_vital} && -f ${ic_src_file} ) then
   /ncrc/home1/Kun.Gao/vi_driver/scripts_for_rt/prepare_tc_files.py -d ${CDATE} -w $min_wind -l $max_lat -i $ic_dir -f $obs_vital -o $vital_dir_processed
endif

# === trigger VI script

if (-f ${vital_dir_processed}/${CDATE}/tcvitals.vi ) then

     # Safety check needed?
     if ( ! -f $ic_dst_file ) then
       set atcf_file = `cd ${vital_dir_processed}/${CDATE} && ls *atcf*`
       set STORMID=`echo $atcf_file  | cut -c1-3`
       echo 'submitting' $CDATE, $STORMID

       # The VI script should trigger T-SHiELD forecast    
       #sbatch --job-name=vi_ic_${CDATE} --export=CDATE=${CDATE},STORMID=${STORMID},ALL ${vi_script}
     endif

endif
