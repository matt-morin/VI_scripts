##!/bin/tcsh

set hh_list=(00 12)
#set initial=20220901
#set end=30
set initial=20200820
set end=52

set hh_list=(00)
set initial=20210905
set end=2
set int=20

set script = /ncrc/home1/Kun.Gao/vi_driver/scripts_for_ic/exhafs_atm_vi_ic_general_v2.sh
set vital_dir = /ncrc/home1/Kun.Gao/vi_driver/tc_vitals/processed_ic/

set i=0
set x=0
while ($x < $end)

  set DATE = `date -d "$initial $i days" +%Y%m%d`

  foreach hh ($hh_list)
  # check if model restart files and processed vitial files exist
  set ic_for_vi_dir = /lustre/f2/dev/Kun.Gao/SHiELD_IC_v16/C768r10n4_atl_new/${DATE}.${hh}Z_IC/vi/
  set ic_src_file = ${ic_for_vi_dir}/gfs_data.tile7_for_vi.nc
  set ic_dst_file = ${ic_for_vi_dir}/gfs_data.tile7_after_vi.nc
  set vital_file = ${vital_dir}/${DATE}${hh}/tcvitals.vi

  if (-f $vital_file  && -f $ic_src_file && ! -f $ic_dst_file ) then
     set CDATE=$DATE$hh
     set atcf_file = `cd ${vital_dir}/${DATE}${hh} && ls *atcf*`
     set STORMID=`echo $atcf_file  | cut -c1-3`
     echo 'submitting' $CDATE, $STORMID
     sbatch --job-name=vi_ic_${CDATE} --export=CDATE=${CDATE},STORMID=${STORMID},ALL ${script} 
  endif

  end
  @ i = $i + $int
  @ x++
end
