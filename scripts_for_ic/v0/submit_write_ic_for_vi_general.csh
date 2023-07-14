#!/bin/tcsh

set hh_list=(00) # 12)
set initial=20220901
set end=30
set int=1

#set initial=20210820
#set end=52
#set int=1

set vital_dir = /ncrc/home1/Kun.Gao/vi_driver/tc_vitals/processed_ic/
set script = /ncrc/home1/Kun.Gao/vi_driver/scripts_for_ic/write_ic_for_vi_general.csh
set ic_base = /lustre/f2/dev/Kun.Gao/SHiELD_IC_v16/C768r10n4_atl_new

set i=0
set x=0
while ($x < $end)
  set DATE = `date -d "$initial $i days" +%Y%m%d`

  foreach hh ($hh_list)
  set source_dir = ${ic_base}/${DATE}.${hh}Z_IC/
  set target_dir = ${ic_base}/${DATE}.${hh}Z_IC/vi/
  set vital_file = ${vital_dir}/${DATE}${hh}/tcvitals.vi

  #echo $source_dir
  #echo $target_dir

  mkdir -p $target_dir

  set file1 = ${source_dir}'/gfs_data.tile7.nc'
  set file2 = ${target_dir}'/gfs_data.tile7_for_vi.nc'

  if (-f $vital_file && -f $file1  && ! -f $file2 ) then
     echo 'submitting job for' $DATE.$hh
     sbatch --job-name=write_ic_for_vi_${DATE} --export=source_dir=${source_dir},target_dir=${target_dir},ALL ${script} 
  endif

  end
  @ i = $i + $int
  @ x++
end
