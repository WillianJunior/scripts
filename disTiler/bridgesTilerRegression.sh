#!/bin/bash
#SBATCH -N 1
#SBATCH -p RM
#SBATCH --ntasks-per-node 4
#SBATCH -t 4:00:00

set -x

IMAGES_ZIP=$1

cp * $LOCAL

cd $LOCAL

bash tilerTimeXcostXiterations.sh IMAGES_ZIP
