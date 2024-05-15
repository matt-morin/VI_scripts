import datetime as dt
import numpy as np
import os
import sys
import glob
import json

sys.path.append('/misc/whome/Kun.Gao/NGGPS/py_functions/')
from vi_functions import *

write_out_json = True

version = 'v2.5'

vital_base = '/misc/whome/role.rthfip-gfdl/NGGPS/vi_driver/scripts_for_rt/tc_vitals/processed/'
work_base = '/mnt/lfs1/HFIP/hfip-gfdl/Kun.Gao/vi_work_rt2023/'
ic_base = '/mnt/lfs1/HFIP/hfip-gfdl/role.rthfip-gfdl/SHiELD_INPUT_DATA/variable.v202101/C768r10n4_atl_new/'

date_list = []
date1 = dt.datetime.strptime('2023080100',"%Y%m%d%H")
for t in np.arange(4*90):
      date1 = date1 + dt.timedelta(days=0.25)
      date_list.append(date1.strftime("%Y%m%d%H"))

dict_good = {}

for date in date_list:

 ic_file_dst = ic_base + date[:8] + '.' + date[-2:] + 'Z_IC/gfs_data.tile7_vi_'+version+'.nc'

 obs_vital = vital_base + date + '/tcvitals.vi'
 if os.path.exists(obs_vital):
  tc_dict = read_tcvitals(obs_vital)
  tc_id_list = list(tc_dict.keys())
  stormID = tc_id_list[0][2:]

  work_dir_ = work_base + date + '/' + stormID + '/'
  work_dirs = glob.glob(work_dir_)

  if len(work_dirs) == 1:

    print ('='*20, date)
    work_dir = work_dirs[0]

    if os.path.exists(work_dir) and os.path.exists(ic_file_dst):
      print ('VI is good')
      dict_good[date] = stormID
    else:
      print ('VI did not work')

if write_out_json:
   with open("good_vi_list.json", "w") as outfile:
     json.dump(dict_good, outfile, indent=0, sort_keys=True)

