#!/bin/tcsh
#SBATCH --output=/ncrc/home1/Kun.Gao/vi_driver/stdout/%x.o%j
#SBATCH --job-name=write_ic_for_vi
#SBATCH --partition=batch
#SBATCH --account=gfdl_W
#SBATCH --qos=urgent
#SBATCH --ntasks=1
#SBATCH --time=03:00:00
#SBATCH --cluster=c4

#set -xe

module load PythonEnv-noaa/1.5.0
python /ncrc/home1/Kun.Gao/vi_driver/scripts_for_ic/write_ic_for_vi.py -a $source_dir -b $target_dir

exit
