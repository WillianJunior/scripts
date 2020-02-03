#!/bin/bash
#SBATCH -N 1
#SBATCH -p RM
#SBATCH --ntasks-per-node 28
#SBATCH -t 4:00:00

set -x

IMAGES_ZIP=$1

cp * $LOCAL

cd $LOCAL

module load cmake/3.11.4 cuda/10.1 gcc/6.3.0 openslide/3.4.1 mpi/gcc_openmpi

bash tilerTimeXcostXiterations.sh $IMAGES_ZIP
