import numpy as np
from netCDF4 import Dataset
import getopt
import sys

# Input needed:
# source_dir
# target_dir

# --- get the arguments from the command line
argv = sys.argv[1:]
try:
    opts, args = getopt.getopt(argv, 'a:b:', ['foperand', 'soperand'])
    if len(opts) == 0 and len(opts) > 2:
      print ('usage: name.py -a <first_operand> -b <second_operand>')
    else:
      for opt, arg in opts:
          if opt == '-a':
             source_dir = arg
          if opt == '-b':
             target_dir = arg
except getopt.GetoptError:
    print ('wrong args')
    sys.exit(2)

# --- optional paramters
file = 'gfs_data.tile7.nc'
file_ctrl = 'gfs_ctrl.nc'

zind1 = 27   
zind2 = 127 # last layer 

nx = 2304
ny = 1152
nz = zind2-zind1+1

var_list = ['wind', 'zh','delp','t','sphum','w','vcoord']

# --- main program

fd = Dataset(source_dir+'/'+file, 'r')
fd_ctrl = Dataset(source_dir+'/'+file_ctrl, 'r')

file_name = target_dir+'/gfs_data.tile7_for_vi.nc'

print('=== writing to', file_name)

fnc = Dataset(file_name, 'w',format='NETCDF4_CLASSIC')

lon = fnc.createDimension('lon', nx)
lat = fnc.createDimension('lat', ny)
lev = fnc.createDimension('lev', nz)
levp = fnc.createDimension('levp', nz+1)
nvcoord = fnc.createDimension('nvcoord', 2)

for var_name in var_list:
 
 print ('dealing', var_name)

 if var_name == 'wind':
    us = np.squeeze(fd.variables['u_s'][zind1:zind2+1,:,:])
    vs = np.squeeze(fd.variables['v_s'][zind1:zind2+1,:,:])
    ua = 0.5*(us[:,:-1,:]+us[:,1:,:])
    va = 0.5*(vs[:,:-1,:]+vs[:,1:,:])
    var_w = fnc.createVariable('u', np.float32, ('lev', 'lat', 'lon'))
    var_w[:,:,:] = ua
    var_w = fnc.createVariable('v', np.float32, ('lev', 'lat', 'lon'))
    var_w[:,:,:] = va
 elif var_name == 'zh':
    var = np.squeeze(fd.variables[var_name][zind1:zind2+2,:,:])
    var_w = fnc.createVariable(var_name, np.float32, ('levp', 'lat', 'lon'))
    var_w[:,:,:] = var
 elif var_name == 'vcoord':
    var = np.squeeze(fd_ctrl.variables[var_name][:,zind1:zind2+2])
    var_w = fnc.createVariable(var_name, np.float32, ('nvcoord', 'levp'))
    var_w[:,:] = var
    
    #print 'ptop', var[0,0]
    #print var[0,:]
    #print var[1,:]

 else:
    var = np.squeeze(fd.variables[var_name][zind1:zind2+1,:,:])
    var_w = fnc.createVariable(var_name, np.float32, ('lev', 'lat', 'lon'))
    var_w[:,:,:] = var

fnc.close()

