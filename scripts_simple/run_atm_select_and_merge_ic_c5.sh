#!/bin/bash
#SBATCH --output=/ncrc/home1/Kun.Gao/vi_driver/stdout/%x.o%j
#SBATCH --job-name=atm_vi_ic_test
#SBATCH --partition=batch
#SBATCH --account=gfdl_W
#SBATCH --qos=urgent
#SBATCH --ntasks=1
#SBATCH --time=03:00:00
#SBATCH --cluster=c5

#set -xe
set -x # for C5

ulimit

# ---> setting up 

export do_select=1
export do_update=0

export vortexradius=10
export res=0.20 # 0.02 or 0.20
export nest_grids=0 # ndom=nestdoms+1

export exec=exec #_c5_ic

export CDATE=2022092000
export STORMID=07L

export vital_dir=/ncrc/home1/Kun.Gao/vi_driver/tc_vitals/processed_vi1/
export ic_base_dir=/lustre/f2/dev/gfdl/Kun.Gao/SHiELD_IC_v16/C768r10n4_atl_vi/
export grid_dir=${ic_base_dir}/INPUT/
export ic_src_dir=${ic_base_dir}/20220920.00Z_IC/
#export ic_dst_dir=${ic_base_dir}/20220920.00Z_IC_test/

export work_dir=/lustre/f2/scratch/gfdl/Kun.Gao/tshield_vi_work_ic/${CDATE}/${STORMID}_test
export work_dir_in=${work_dir}/intercom/ic_ori
export work_dir_out=${work_dir}/intercom/ic_new
export work_dir_vi=${work_dir}/atm_vi

#rm -rf $work_dir_out
#rm -rf $work_dir
mkdir -p $work_dir
mkdir -p $work_dir_in
mkdir -p $work_dir_out
mkdir -p $work_dir_vi

export HOMEhafs=/ncrc/home1/Kun.Gao/hafs_tools/
export USHhafs=${HOMEhafs}/ush
export EXEChafs=${HOMEhafs}/sorc/hafs_tools.fd/${exec}/
export FIXhafs=${HOMEhafs}/fix

source ${USHhafs}/hafs_pre_job.sh.inc > /dev/null 2>&1
module use ${HOMEhafs}/modulefiles
module load modulefile.hafs.gaea_c5 > /dev/null 2>&1
#module list

export APRUNC=${APRUNC:-"srun --ntasks=8"}
export APRUNC1=${APRUNC1:-"srun --ntasks=1"}
export DATOOL=${DATOOL:-${EXEChafs}/hafs_datool.x}

#===============================================================================
# prepare data 

# tc files
cp $vital_dir/$CDATE/tcvitals.vi $work_dir/

# prepare input files
ln -sf ${grid_dir}/grid_spec.nest02.tile7.nc ${work_dir_in}/grid_spec.nc
ln -sf ${ic_src_dir}/sfc_data.tile7.nc    ${work_dir_in}/sfc_data.nc
ln -sf ${ic_src_dir}/vi/gfs_data.tile7_for_vi.nc    ${work_dir_in}/gfs_data.nc

# prepare output files (to be updated later)
ln -sf ${grid_dir}/grid_spec.nest02.tile7.nc ${work_dir_out}/grid_spec.nc
#cp     ${ic_src_dir}/vi/gfs_data.tile7_for_vi.nc    ${work_dir_out}/gfs_data.nc

cd $work_dir_vi
cp ${work_dir}/tcvitals.vi .
tcvital=${work_dir_vi}/tcvitals.vi
#vmax_vit=`cat ${tcvital} | cut -c68-69`

#===============================================================================
# select small box from source dataset 

if [ ${do_select} -gt 0 ]; then

  prep_dir=${work_dir_vi}/prep_init
  mkdir -p ${prep_dir}

  cd ${prep_dir}
  ${APRUNC} ${DATOOL} hafsvi_preproc_ic --in_dir=${work_dir_in} \
                                     --debug_level=11 --interpolation_points=4 \
                                     --infile_date=${CDATE:0:8}.${CDATE:8:2}0000 \
                                     --tcvital=${tcvital} \
                                     --vortexradius=${vortexradius} --res=${res} \
                                     --nestdoms=${nest_grids} \
                                     --out_file=vi_inp_${vortexradius}deg${res/\./p}.bin
fi

#===============================================================================
# merge back 

if [ ${do_update} -gt 0 ]; then

  ${APRUNC1} ${DATOOL} hafsvi_postproc_ic --in_file=${work_dir_vi}/prep_init/vi_inp_${vortexradius}deg${res/\./p}.bin \
                               --debug_level=11 --interpolation_points=4 \
                               --relaxzone=30 \
                               --infile_date=${CDATE:0:8}.${CDATE:8:2}0000 \
                               --nestdoms=${nest_grids} \
                               --out_dir=${work_dir_out}
#                              [--relaxzone=50 (grids, default is 30) ]
#                              [--debug_level=10 (default is 1) ]
#                              [--interpolation_points=5 (default is 4, range 1-500) ]

fi

#===============================================================================
# check
module load cdo
mkdir -p $work_dir/intercom/check
cd $work_dir/intercom/check
cdo selvar,u -sellevel,101 ${work_dir_in}/gfs_data.nc u_before.nc
cdo selvar,u -sellevel,101 ${work_dir_out}/gfs_data.nc u_after.nc
cdo selvar,sphum -sellevel,101 ${work_dir_in}/gfs_data.nc sphum_before.nc
cdo selvar,sphum -sellevel,101 ${work_dir_out}/gfs_data.nc sphum_after.nc
