#!/bin/tcsh

set hh_list=(00) # 12)
set initial=20220901
set end=30
set int=1

#set initial=20210820
#set end=52
#set int=1

set script = /ncrc/home1/Kun.Gao/vi_driver/scripts_for_ic/update_ic_general.csh
set ic_base = /lustre/f2/dev/Kun.Gao/SHiELD_IC_v16/C768r10n4_atl_new

set i=0
set x=0
while ($x < $end)
  set DATE = `date -d "$initial $i days" +%Y%m%d`

  foreach hh ($hh_list)
  set ic_dir = ${ic_base}/${DATE}.${hh}Z_IC/

  set file1 = ${ic_dir}'/gfs_data.tile7.nc'
  set file2 = ${ic_dir}'/vi/gfs_data.tile7_for_vi.nc'
  set file3 = ${ic_dir}'/vi/gfs_data.tile7_after_vi.nc'

  if (-f $file1 && -f $file2  && -f $file3 ) then
     echo 'submitting job for' $DATE.$hh
     sbatch --job-name=update_ic_${DATE} --export=ic_dir=${ic_dir},ALL ${script} 
  endif

  end
  @ i = $i + $int
  @ x++
end
