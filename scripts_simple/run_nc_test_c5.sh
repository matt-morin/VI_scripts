#!/bin/bash
#SBATCH --output=/ncrc/home1/Kun.Gao/vi_driver/stdout/%x.o%j
#SBATCH --job-name=nc_test
#SBATCH --partition=batch
#SBATCH --account=gfdl_W
#SBATCH --qos=urgent
#SBATCH --ntasks=1
#SBATCH --time=03:00:00
#SBATCH --cluster=c5

#set -xe
set -x # for C5

ulimit

export ic_dir=/lustre/f2/dev/Kun.Gao/SHiELD_IC_v16/C768r10n4_atl_vi/20220920.00Z_IC/
export zind_str=11111 #29
export exec=exec

export HOMEhafs=/ncrc/home1/Kun.Gao/hafs_tools/
export USHhafs=${HOMEhafs}/ush
export EXEChafs=${HOMEhafs}/sorc/hafs_tools.fd/${exec}/
export FIXhafs=${HOMEhafs}/fix

source ${USHhafs}/hafs_pre_job.sh.inc > /dev/null 2>&1
module use ${HOMEhafs}/modulefiles
module load modulefile.hafs.gaea_c5 > /dev/null 2>&1
#module list

export APRUNC1=${APRUNC1:-"srun --ntasks=1"}
export DATOOL=${DATOOL:-${EXEChafs}/hafs_datool.x}

export file_ori=${ic_dir}/gfs_data.tile7.nc
export file_before_vi=${ic_dir}/vi/gfs_data.tile7_for_vi_test.nc
export file_dst=${ic_dir}/gfs_data.tile7_vi_test.nc

rm -rf $file_before_vi
rm -rf $file_dst

#${APRUNC1} ${DATOOL} hafsvi_create_nc --in_dir=${ic_dir} \
#		                      --zsel=${zind_str} \
#                                      --out_file=${file_before_vi}

cp $file_ori $file_dst
${APRUNC1} ${DATOOL} hafsvi_update_nc --in_dir=${ic_dir}/vi/ \
                                      --zsel=${zind_str} \
                                      --out_file=${file_dst}
