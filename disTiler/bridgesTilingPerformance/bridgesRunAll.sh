#!/bin/sh

# inputs:
if [[ $# < 1 ]]; then
    echo "usage: bash bridgesRunAll.sh <images path>"
    exit 0
fi

module load cmake/3.11.4 cuda/10.1 gcc/6.3.0 openslide/3.4.1 mpi/gcc_openmpi

IMGS_PATH=$1
IMGS=$(readlink -f $(basename $IMGS_PATH)/*)

# params
TILES_PER_NODES=( 1 2 4 8 16 )
N_NODES=( 1 )
ALGS=( 0 )
BORDERS=( 0 )
REPETITIONS=3

COMMIT=$(git rev-parse HEAD)
echo commit: $COMMIT

# send a batch job for each set of repetitions
for IMG in $IMGS; do
	for (( N=0; N<${#N_NODES[@]}; N++ )); do
		for (( A=0; A<${#ALGS[@]}; A++ )); do
			for (( T=0; T<${#TILES_PER_NODES[@]}; T++ )); do
				for (( B=0; B<${#BORDERS[@]}; B++ )); do
					# get variables
					N_N=${N_NODES[$N]}
					ALG=${ALGS[$A]}
					TPN=${TILES_PER_NODES[$T]}
					BORDER=${BORDERS[$B]}

					J="iwpp_$(basename $IMG)_n${N_N}_a${ALG}_t$((${TPN}*${N_N}))_tpn${TPN}_b${BORDER}_r${REPETITIONS}"
					echo "sending $J"
					sbatch -J $J -N $N_N bridgesSingleBatch.sh $IMG $N_N $ALG $TPN $BORDER $REPETITIONS $COMMIT
				done
			done
		done
	done
done



