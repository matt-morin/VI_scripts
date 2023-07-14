#!/bin/tcsh
#SBATCH --output=/ncrc/home1/Kun.Gao/vi_driver/stdout/%x.o%j
#SBATCH --job-name=update_ic
#SBATCH --partition=batch
#SBATCH --account=gfdl_W
#SBATCH --qos=urgent
#SBATCH --ntasks=1
#SBATCH --time=03:00:00
#SBATCH --cluster=c4

#set -xe

module load PythonEnv-noaa/1.5.0
python /ncrc/home1/Kun.Gao/vi_driver/scripts_for_ic/update_ic.py -a $ic_dir

exit
