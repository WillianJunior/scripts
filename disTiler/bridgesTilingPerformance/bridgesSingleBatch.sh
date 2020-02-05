#!/bin/bash
#SBATCH -p RM
#SBATCH --ntasks-per-node 28
#SBATCH -t 1:00:00

# set -x

# inputs:
if [[ $# < 7 ]]; then
    echo "usage: bash bridgesSingleBatch.sh <> <> ..."
    exit 0
fi

# module load cmake/3.11.4 cuda/10.1 gcc/6.3.0 openslide/3.4.1 mpi/gcc_openmpi
# cp * $LOCAL

RTF_PARAMS="-c 1 -g 1 -a 1"
MPI_PARAMS="--bind-to none"
IMG=$1
N_N=$2
ALG=$3
TPN=$4
BORDER=$5
REPS=$6
COMMIT=$7

cp $IMG $LOCAL
cd $LOCAL

WARMUP=2

echo "mpirun -np $((${N_N}+1)) $MPI_PARAMS ./iwpp $IMG $RTF_PARAMS -d $ALG -b $BORDER -t $TPN"
echo commit: $COMMIT

for (( W=1; W<=${WARMUP}; W++ )); do
	echo warmup $W
	mpirun -np $((${N_N}+1)) $MPI_PARAMS ./iwpp $IMG $RTF_PARAMS -d $ALG -b $BORDER -t $TPN
done

for (( R=1; R<=${REPS}; R++ )); do
	echo rep $R
	OUT=commit: $COMMIT$'\n'$(mpirun -np $((${N_N}+1)) $MPI_PARAMS ./iwpp $IMG $RTF_PARAMS -d $ALG -b $BORDER -t $TPN)
	echo $OUT > iwpp_$(basename $IMG)_n${N_N}_a${ALG}_t$((${TPN}*${N_N}))_tpn${TPN}_b${BORDER}_r${R}.log
done

