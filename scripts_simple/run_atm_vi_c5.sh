#!/bin/bash
#SBATCH --output=/ncrc/home1/Kun.Gao/tshield_vi_driver/stdout/%x.o%j
#SBATCH --job-name=atm_vi_simple
#SBATCH --partition=batch
#SBATCH --account=gfdl_W
#SBATCH --qos=urgent
#SBATCH --ntasks=1
#SBATCH --time=00:20:00
#SBATCH --cluster=c3
#SBATCH --export=NONE

#set -xe
set -x # for C5

ulimit

# We assume the preprocessing step is done (box1 and box2 data are ready to be used)

# ---> optional setting 

export basin=AL
export initopt=0
export gfs_flag=0
export gesfhr=6 # basically useless; only useful in setting the value for item in split.f
export ibgs=2
export iflag_cold=1

export do_split=0
export do_pert=0
export do_combine=1
export do_enhance=1

export split_dir_tag=''
export pert_dir_tag=''
export combine_dir_tag='_test'
export exec=exec_dev_enhance

export CDATE=2021090500
export STORMID=12L
#export CDATE=2021092500
#export STORMID=18L
#export CDATE=2022092000
#export STORMID=07L

#export WORKhafs=/lustre/f2/scratch/gfdl/Kun.Gao/tshield_vi_work_dev/${CDATE}/${STORMID}
export WORKhafs=/lustre/f2/scratch/gfdl/Kun.Gao/tshield_vi_work_ic_v2/${CDATE}/${STORMID}

export deg_box1=10
export deg_box2=10

export vital_dir=/ncrc/home1/Kun.Gao/vi_driver/tc_vitals/processed_ic/

# <--- end setting 

export HOMEhafs=/ncrc/home1/Kun.Gao/hafs_tools/
export USHhafs=${HOMEhafs}/ush
export EXEChafs=${HOMEhafs}/sorc/hafs_tools.fd/${exec}/
export FIXhafs=${HOMEhafs}/fix

source ${USHhafs}/hafs_pre_job.sh.inc > /dev/null 2>&1
module use ${HOMEhafs}/modulefiles
module load modulefile.hafs.gaea_c5 > /dev/null 2>&1

export INTCOMinit=${WORKhafs}/intercom/atm_init
export DATA=${WORKhafs}/atm_vi/
export work_dir_split=${DATA}/split_init${split_dir_tag}/
export work_dir_pert=${DATA}/anl_pert_init${pert_dir_tag}/
export work_dir_combine=${DATA}/anl_storm${combine_dir_tag}/

tcvital=${WORKhafs}/data/tcvitals.vi
vmax_vit=`cat ${tcvital} | cut -c68-69`

# We assume the preprocessing step is done (box1 and box2 data are ready to be used)

# --- 1. split step

if [ ${do_split} -gt 0 ]; then

  rm -rf ${work_dir_split}
  mkdir -p ${work_dir_split}
  cd ${work_dir_split}	

  # 1.1 -- create_trak
  # input
  ln -sf ${tcvital} fort.11
  if [ -e ${INTCOMinit}/${STORMID}.${CDATE}.trak.atcfunix.all ]; then
    ln -sf ${INTCOMinit}/${STORMID}.${CDATE}.trak.atcfunix.all ./trak.atcfunix.all
    grep "^.., ${STORMID:0:2}," trak.atcfunix.all > trak.atcfunix.tmp
  else
    touch trak.atcfunix.tmp
  fi
  ln -sf trak.atcfunix.tmp fort.12
  # output
  ln -sf ./trak.fnl.all fort.30

  ln -sf ${EXEChafs}/hafs_vi_create_trak_init.x ./
  time ./hafs_vi_create_trak_init.x ${STORMID}

  # -- 1.2 split

  # input
  ln -sf ${tcvital} fort.11
  ln -sf ./trak.fnl.all fort.30
  ln -sf ../prep_init/vi_inp_${deg_box1}deg0p02.bin ./fort.26
  ln -sf ../prep_init/vi_inp_${deg_box2}deg0p20.bin ./fort.46
  # output
  ln -sf storm_env                     fort.56
  ln -sf rel_inform                    fort.52
  ln -sf vital_syn                     fort.55
  ln -sf storm_pert                    fort.71
  ln -sf storm_radius                  fort.85

  ln -sf ${EXEChafs}/hafs_vi_split.x ./
  echo ${gesfhr} $ibgs $vmax_vit $iflag_cold 1.0 | ./hafs_vi_split.x > log
fi

# --- 2. anl_pert step

if [ ${do_pert} -gt 0 ]; then

  rm -rf ${work_dir_pert}
  mkdir -p ${work_dir_pert}
  cd ${work_dir_pert}

  # input
  ln -sf ${tcvital} fort.11
  ln -sf ../prep_init/vi_inp_${deg_box1}deg0p02.bin fort.46

  ln -sf ${work_dir_split}/storm_env fort.26
  ln -sf ${work_dir_split}/storm_pert fort.71
  ln -sf ${work_dir_split}/storm_radius fort.65
  # output
  ln -sf storm_pert_new fort.58
  ln -sf storm_size_p fort.14
  ln -sf storm_sym fort.23

  ln -sf ${EXEChafs}/hafs_vi_anl_pert.x ./
  echo 6 ${basin} ${initopt} | ./hafs_vi_anl_pert.x > log

fi

# --- 3. anl_combine step

if [ ${do_combine} -gt 0 ]; then

  rm -rf ${work_dir_combine}
  mkdir -p ${work_dir_combine}
  cd ${work_dir_combine}

  # input
  ln -sf ${tcvital} fort.11
  ln -sf ../prep_init/vi_inp_${deg_box1}deg0p02.bin ./fort.46 #roughness

  ln -sf ${work_dir_split}/trak.atcfunix.tmp fort.12
  ln -sf ${work_dir_split}/trak.fnl.all fort.30
  ln -sf ${work_dir_split}/storm_env fort.26
  ln -sf ${work_dir_split}/storm_radius fort.85 # filter domain mean radius

  ln -sf ${work_dir_pert}/storm_size_p fort.14
  ln -sf ${work_dir_pert}/storm_sym fort.23
  ln -sf ${work_dir_pert}/storm_pert_new fort.71

  # output
  ln -sf storm_env_new                 fort.36
  ln -sf storm_anl_combine             fort.56

  ln -sf ${EXEChafs}/hafs_vi_anl_combine.x ./
  echo ${gesfhr} ${basin} ${gfs_flag} ${initopt} | ./hafs_vi_anl_combine.x > combine_log
  #if [ -s storm_anl_combine ]; then
  #  cp -p storm_anl_combine storm_anl
  #fi
  #cp -p storm_env_new storm_anl # KGao - storm_env_new combines env + stretched hurr pert
fi

# --- 4. anl_enhance step 

if [ ${do_enhance} -gt 0 ]; then
  
  cd ${work_dir_combine}
	
  if [ -s storm_env_new ]; then

    # input
    #ln -sf ../prep_init/vi_inp_${deg_box1}deg0p02.bin ./fort.46 #roughness
    ln -sf ${work_dir_pert}/storm_sym fort.23
    ln -sf storm_env_new fort.26 # from anl_combine step

    ln -sf ${FIXhafs}/fix_vi/hafs_storm_axisy_47 fort.71
    ln -sf ${FIXhafs}/fix_vi/hafs_storm_axisy_47 fort.72
    ln -sf ${FIXhafs}/fix_vi/hafs_storm_axisy_47 fort.73
    ln -sf ${FIXhafs}/fix_vi/hafs_storm_axisy_47 fort.74
    ln -sf ${FIXhafs}/fix_vi/hafs_storm_30       fort.75
    ln -sf ${FIXhafs}/fix_vi/hafs_storm_30       fort.76
    ln -sf ${FIXhafs}/fix_vi/hafs_storm_30       fort.77
    ln -sf ${FIXhafs}/fix_vi/hafs_storm_axisy_47 fort.78

    # output
    ln -sf storm_anl_enhance                     fort.56

    ln -sf ${EXEChafs}/hafs_vi_anl_enhance.x ./
    echo 6 ${basin} ${iflag_cold} | ./hafs_vi_anl_enhance.x > enhance.log
    #cp -p storm_anl_enhance storm_anl

  fi
fi
