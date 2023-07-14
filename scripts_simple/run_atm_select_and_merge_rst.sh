#!/bin/bash
#SBATCH --output=/ncrc/home1/Kun.Gao/tshield_vi_driver/stdout/%x.o%j
#SBATCH --job-name=atm_merge
#SBATCH --partition=batch
#SBATCH --account=gfdl_W
#SBATCH --qos=urgent
#SBATCH --ntasks=1
#SBATCH --time=03:00:00
#SBATCH --cluster=c4

set -xe
ulimit

# ---> setting up 
export do_select=0

export vortexradius=20
export res=0.02
export nest_grids=1

export vital_dir=/ncrc/home1/Kun.Gao/tshield_vi_driver/tc_vitals/processed_vi1/
export rst_dir=/lustre/f2/dev/Kun.Gao/tshield_vi/20220920.00Z.C768r10n4_atl_vi_large.nh.32bit.non-mono.0h/rundir/
export CDATE=2022092000
export STORMID=07L

export exec=exec_da_new
export WORKhafs=/lustre/f2/scratch/gfdl/Kun.Gao/tshield_vi_dev/${CDATE}/${STORMID}
export static_dir=/lustre/f2/dev/Kun.Gao/tshield_vi/static/
export rst_src_dir=$rst_dir/RESTART/
export rst_work_dir=$WORKhafs/intercom/RESTART_init

export RESTARTinit=${RESTARTinit:-${WORKhafs}/intercom/RESTART_init}
export RESTARTdst=${RESTARTinit}
export RESTARTout=${RESTARTout:-${WORKhafs}/intercom/RESTART_vi_test}
export DATA=${DATA:-${WORKhafs}/atm_vi}

rm -rf $RESTARTout

#rm -rf $WORKhafs
mkdir -p $WORKhafs
mkdir -p $RESTARTinit
mkdir -p $RESTARTout
mkdir -p $DATA

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
export NCP=${NCP:-"/bin/cp"}
export DATOOL=${DATOOL:-${EXEChafs}/hafs_datool.x}

#===============================================================================
# prepare data 

# tc files
cp $vital_dir/$CDATE/tcvitals.vi $WORKhafs/

# nc files
export datetime=${CDATE:0:8}.${CDATE:8:2}0000
ln -sf ${rst_src_dir}/fv_core.res.nest02.nc          ${rst_work_dir}/${datetime}.fv_core.res.nc
ln -sf ${rst_src_dir}/fv_core.res.nest02.tile7.nc    ${rst_work_dir}/${datetime}.fv_core.res.tile1.nc
ln -sf ${rst_src_dir}/fv_tracer.res.nest02.tile7.nc  ${rst_work_dir}/${datetime}.fv_tracer.res.tile1.nc
ln -sf ${rst_src_dir}/fv_srf_wnd.res.nest02.tile7.nc ${rst_work_dir}/${datetime}.fv_srf_wnd.res.tile1.nc
ln -sf ${rst_src_dir}/phy_data.nest02.tile7.nc       ${rst_work_dir}/${datetime}.phy_data.nc
ln -sf ${rst_src_dir}/sfc_data.nest02.tile7.nc       ${rst_work_dir}/${datetime}.sfc_data.nc
ln -sf ${static_dir}/*                               ${rst_work_dir}

cd $DATA
cp ${WORKhafs}/tcvitals.vi .
tcvital=${DATA}/tcvitals.vi
#vmax_vit=`cat ${tcvital} | cut -c68-69`

#===============================================================================
# select small box from source dataset 

if [ ${do_select} -gt 0 ]; then

  work_dir=${DATA}/prep_init
  cd $DATA

  mkdir -p ${work_dir}
  cd ${work_dir}
  ${APRUNC} ${DATOOL} hafsvi_preproc --in_dir=${RESTARTinit} \
                                     --debug_level=11 --interpolation_points=4 \
                                     --infile_date=${CDATE:0:8}.${CDATE:8:2}0000 \
                                     --tcvital=${tcvital} \
                                     --vortexradius=${vortexradius} --res=${res} \
                                     --nestdoms=$((${nest_grids:-1}-1)) \
                                     --out_file=vi_inp_${vortexradius}deg${res/\./p}.bin
fi

#===============================================================================
# use the selected source data to replace target dataset

# below are just hyperlinks
${NCP} -rp ${RESTARTdst}/${CDATE:0:8}.${CDATE:8:2}0000* ${RESTARTout}/
${NCP} -rp ${RESTARTdst}/atmos_static*.nc ${RESTARTout}/
${NCP} -rp ${RESTARTdst}/grid_*spec*.nc ${RESTARTout}/
${NCP} -rp ${RESTARTdst}/oro_data*.nc ${RESTARTout}/

# copy over the two actual files (will be modified)
rm ${RESTARTout}/${datetime}.fv_core.res.tile1.nc
rm ${RESTARTout}/${datetime}.fv_tracer.res.tile1.nc
${NCP} ${rst_src_dir}/fv_core.res.nest02.tile7.nc    ${RESTARTout}/${datetime}.fv_core.res.tile1.nc
${NCP} ${rst_src_dir}/fv_tracer.res.nest02.tile7.nc  ${RESTARTout}/${datetime}.fv_tracer.res.tile1.nc

for nd in $(seq 1 ${nest_grids})
do

${APRUNC1} ${DATOOL} hafsvi_postproc --in_file=${DATA}/prep_init/vi_inp_${vortexradius}deg${res/\./p}.bin \
                               --debug_level=11 --interpolation_points=4 \
                               --relaxzone=30 \
                               --infile_date=${CDATE:0:8}.${CDATE:8:2}0000 \
                               --nestdoms=$((${nd}-1)) \
                               --out_dir=${RESTARTout}
#                              [--relaxzone=50 (grids, default is 30) ]
#                              [--debug_level=10 (default is 1) ]
#                              [--interpolation_points=5 (default is 4, range 1-500) ]
done
#===============================================================================

# copy modified restart files to tshield rundir 
# need to check hafsvi_postproc is successful

module load cdo

mkdir -p $WORKhafs/intercom/check
cd $WORKhafs/intercom/check
cdo selvar,u -sellevel,75 ${RESTARTdst}/${datetime}.fv_core.res.tile1.nc u_before.nc
cdo selvar,u -sellevel,75 ${RESTARTout}/${datetime}.fv_core.res.tile1.nc u_after.nc
cdo selvar,sphum -sellevel,75 ${RESTARTdst}/${datetime}.fv_tracer.res.tile1.nc sphum_before.nc
cdo selvar,sphum -sellevel,75 ${RESTARTout}/${datetime}.fv_tracer.res.tile1.nc sphum_after.nc
