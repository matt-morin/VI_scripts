import numpy as np
from netCDF4 import Dataset
import getopt
import sys
import os

import sys
sys.path.append('/ncrc/home1/Kun.Gao/py_functions/')
from vi_functions import *

# Input needed:
# ic_dir

# --- get the arguments from the command line
argv = sys.argv[1:]
try:
    opts, args = getopt.getopt(argv, 'a:', ['foperand'])
    if len(opts) == 0 and len(opts) > 1:
      print ('usage: name.py -a <first_operand>')
    else:
      for opt, arg in opts:
          if opt == '-a':
             ic_dir = arg
except getopt.GetoptError:
    print ('wrong args')
    sys.exit(2)

# --- optional settings

zind1 = 27   
zind2 = 127 # last layer 

var_list = ['wind', 'delp','t','sphum']

# --- main program

file_dst = ic_dir + '/gfs_data.tile7_vi.nc' # IC file to be updated
file_vi_in = ic_dir + 'vi/gfs_data.tile7_for_vi.nc' # proprocessed IC file for VI
file_vi_out = ic_dir + 'vi/gfs_data.tile7_after_vi.nc' # adjusted IC file after VI

if os.path.exists(file_dst):
   cmd = 'rm -r {}'.format(file_dst)
   os.system(cmd)
#if not os.path.exists(file_dst):
cmd = 'cp {} {}'.format(ic_dir+'/gfs_data.tile7.nc',  file_dst)
os.system(cmd)

fd_dst = Dataset(file_dst, 'r+')
fd_vi_in = Dataset(file_vi_in, 'r')
fd_vi_out = Dataset(file_vi_out, 'r')

for var_name in var_list:
 
 print 'dealing', var_name

 if var_name == 'wind':
    for i in range(2):
        if i == 0:
           # u-comp
           dvar = fd_vi_out.variables['u'][:,:,:] - fd_vi_in.variables['u'][:,:,:]
           dvar_w, dvar_s = map_dvar_to_cgrid(dvar)
           fd_dst['u_w'][zind1:zind2+1,:,:] += dvar_w
           fd_dst['u_s'][zind1:zind2+1,:,:] += dvar_s
        else:
           # v-comp
           dvar = fd_vi_out.variables['v'][:,:,:] - fd_vi_in.variables['v'][:,:,:]
           dvar_w, dvar_s = map_dvar_to_cgrid(dvar)
           fd_dst['v_w'][zind1:zind2+1,:,:] += dvar_w
           fd_dst['v_s'][zind1:zind2+1,:,:] += dvar_s
 else:
    var = fd_vi_out[var_name][:,:,:]
    #print np.shape(var)
    var_ori = fd_dst[var_name][zind1:zind2+1,:,:] 
    #print np.shape(var_ori)
    fd_dst[var_name][zind1:zind2+1,:,:] = var

fd_dst.close()
fd_vi_in.close()
fd_vi_out.close()

