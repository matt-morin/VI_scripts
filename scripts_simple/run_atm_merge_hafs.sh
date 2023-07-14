#!/bin/bash
#SBATCH --output=/ncrc/home1/Kun.Gao/tshield_vi_driver/stdout/%x.o%j
#SBATCH --job-name=atm_merge_hafs
#SBATCH --partition=batch
#SBATCH --account=gfdl_W
#SBATCH --qos=urgent
#SBATCH --ntasks=1
#SBATCH --time=03:00:00
#SBATCH --cluster=c4

set -xe
ulimit

# ---> setting up 

export do_select=1

export vortexradius=8
export res=0.02
export nest_grids=1

export exec=exec_da_new

export CDATE=2022092312
export STORMID=12L

export vital_dir=/ncrc/home1/Kun.Gao/tshield_vi_driver/tc_vitals_m2/processed_vi1/
export rst_src_dir=/lustre/f2/dev/gfdl/Kun.Gao/hafstmp/hafa_final/2022092312/12L/intercom/RESTART_analysis_merge/
export rst_tgt_dir=/lustre/f2/dev/Kun.Gao/tshield_vi_l81/20220923.12Z.C768r10n4_atl_vi.nh.32bit.non-mono.tsh22_l81_0h/rundir/RESTART/
#export rst_dst_dir=??
export static_dir=/lustre/f2/dev/Kun.Gao/tshield_vi_l81/static/

export work_dir=/lustre/f2/scratch/gfdl/Kun.Gao/tshield_vi_work_m2/${CDATE}/${STORMID}
export work_rst_in=${work_dir}/intercom/RESTART_hafs
export work_rst_out=${work_dir}/intercom/RESTART_merge
export work_dir_vi=${work_dir}/atm_vi

#rm -rf $work_rst_out
#rm -rf $work_dir
mkdir -p $work_dir
mkdir -p $work_rst_in
mkdir -p $work_rst_out
mkdir -p $work_dir_vi

export HOMEhafs=/ncrc/home1/Kun.Gao/hafs_tools/
export USHhafs=${HOMEhafs}/ush
export EXEChafs=${HOMEhafs}/sorc/hafs_tools.fd/${exec}/
export FIXhafs=${HOMEhafs}/fix

source ${USHhafs}/hafs_pre_job.sh.inc > /dev/null 2>&1
module use ${HOMEhafs}/modulefiles
module load modulefile.hafs.gaea > /dev/null 2>&1
#module list

export APRUNC=${APRUNC:-"srun --ntasks=8"}
export APRUNC1=${APRUNC1:-"srun --ntasks=1"}
export DATOOL=${DATOOL:-${EXEChafs}/hafs_datool.x}

#===============================================================================
# prepare data 

# tc files
cp $vital_dir/$CDATE/tcvitals.vi $work_dir/

# link hafs restart files
export datetime=${CDATE:0:8}.${CDATE:8:2}0000

ln -sf ${rst_src_dir}/${datetime}.fv_core.res.nest02.nc          ${work_rst_in}/${datetime}.fv_core.res.nc
ln -sf ${rst_src_dir}/${datetime}.fv_core.res.nest02.tile2.nc    ${work_rst_in}/${datetime}.fv_core.res.tile1.nc
ln -sf ${rst_src_dir}/${datetime}.fv_tracer.res.nest02.tile2.nc  ${work_rst_in}/${datetime}.fv_tracer.res.tile1.nc
ln -sf ${rst_src_dir}/${datetime}.fv_srf_wnd.res.nest02.tile2.nc ${work_rst_in}/${datetime}.fv_srf_wnd.res.tile1.nc
ln -sf ${rst_src_dir}/${datetime}.phy_data.nest02.tile2.nc       ${work_rst_in}/${datetime}.phy_data.nc
ln -sf ${rst_src_dir}/${datetime}.sfc_data.nest02.tile2.nc       ${work_rst_in}/${datetime}.sfc_data.nc
ln -sf ${rst_src_dir}/grid_spec.nest02.tile2.nc                  ${work_rst_in}/grid_spec.nc
ln -sf ${rst_src_dir}/atmos_static.nest02.tile2.nc               ${work_rst_in}/atmos_static.nc
ln -sf ${rst_src_dir}/oro_data.nest02.tile2.nc                   ${work_rst_in}/oro_data.nc

# link tshield restart files
ln -sf ${rst_tgt_dir}/fv_core.res.nest02.nc          ${work_rst_out}/${datetime}.fv_core.res.nc
cp     ${rst_tgt_dir}/fv_core.res.nest02.tile7.nc    ${work_rst_out}/${datetime}.fv_core.res.tile1.nc
cp     ${rst_tgt_dir}/fv_tracer.res.nest02.tile7.nc  ${work_rst_out}/${datetime}.fv_tracer.res.tile1.nc
ln -sf ${rst_tgt_dir}/fv_srf_wnd.res.nest02.tile7.nc ${work_rst_out}/${datetime}.fv_srf_wnd.res.tile1.nc
ln -sf ${rst_tgt_dir}/phy_data.nest02.tile7.nc       ${work_rst_out}/${datetime}.phy_data.nc
ln -sf ${rst_tgt_dir}/sfc_data.nest02.tile7.nc       ${work_rst_out}/${datetime}.sfc_data.nc
ln -sf ${static_dir}/*                               ${work_rst_out}

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
  ${APRUNC} ${DATOOL} hafsvi_preproc --in_dir=${work_rst_in} \
                                     --debug_level=11 --interpolation_points=4 \
                                     --infile_date=${CDATE:0:8}.${CDATE:8:2}0000 \
                                     --tcvital=${tcvital} \
                                     --vortexradius=${vortexradius} --res=${res} \
                                     --nestdoms=$((${nest_grids:-1}-1)) \
                                     --out_file=vi_inp_${vortexradius}deg${res/\./p}.bin
fi

#===============================================================================
# use the selected source data to replace target dataset

for nd in $(seq 1 ${nest_grids})
do

${APRUNC1} ${DATOOL} hafsvi_postproc --in_file=${work_dir_vi}/prep_init/vi_inp_${vortexradius}deg${res/\./p}.bin \
                               --debug_level=11 --interpolation_points=4 \
                               --relaxzone=30 \
                               --infile_date=${CDATE:0:8}.${CDATE:8:2}0000 \
                               --nestdoms=$((${nd}-1)) \
                               --out_dir=${work_rst_out}
#                              [--relaxzone=50 (grids, default is 30) ]
#                              [--debug_level=10 (default is 1) ]
#                              [--interpolation_points=5 (default is 4, range 1-500) ]
done
#===============================================================================

# copy modified restart files to tshield rundir 
# need to check hafsvi_postproc is successful

module load cdo

mkdir -p $work_dir/intercom/check
cd $work_dir/intercom/check
cdo selvar,u -sellevel,81 ${rst_tgt_dir}/fv_core.res.nest02.tile7.nc u_before.nc
cdo selvar,u -sellevel,81 ${work_rst_out}/${datetime}.fv_core.res.tile1.nc u_after.nc

cdo selvar,sphum -sellevel,81 ${rst_tgt_dir}/fv_tracer.res.nest02.tile7.nc sphum_before.nc
cdo selvar,sphum -sellevel,81 ${work_rst_out}/${datetime}.fv_tracer.res.tile1.nc sphum_after.nc
