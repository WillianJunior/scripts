#!/bin/sh

# ls | grep ground | grep tiff | xargs -I {} cp -u {} ~/Desktop/tiles/new

# FILES=$(ls); I=0; for F in ${FILES[@]}; do mv $F tile${I}.tiff; I=$(($I+1)); done

# inputs:
if [[ $# < 3 ]]; then
    echo "usage: bash funcParamTraining.sh <images path> <use erode> \
        <use dilate>"
    echo -e "\t<use erode>: -1 for standard, other number for fixed"
    echo -e "\t<use dilate>: -1 for standard, other number for fixed"
    
    exit 0
fi

# set -x

# bash funcParamTraining.sh ./tiles 4 -1

IMAGES_PATH=$1
IMAGES=$(readlink -f ${IMAGES_PATH}/*)

# set erode
if [[ $2 == -1 ]]; then
    ERODE=( 2 4 6 8 10 )
else
    ERODE=( $2 )
fi

# set dilate
if [[ $3 == -1 ]]; then
    DILATE=( 2 4 6 8 10 )
else
    DILATE=( $3 )
fi

THRS=( 63 95 127 159 191 223 255 ) # step 32

ALG_PRESET=1
TILES_PRESET=1
BORDER=0

pretilingAlgs=0 # no pre-tiling
cpuThreads=1
rm tmp.log
# prints the stddev of timeFactor for a set of input images
for E in ${ERODE[@]}; do
    for D in ${DILATE[@]}; do
        for T in ${THRS[@]}; do
            TF_LIST=""
            PARAMS="${T}/${E}/${D}"
            # echo "testing $PARAMS"
            echo "testing $PARAMS" >> tmp.log
            for IMG in ${IMAGES[@]}; do
                echo "img $IMG" >> tmp.log
                # echo "img $IMG"
                # execute for this image and parameters
                OUT=$(mpirun -np 2 ./iwpp ${IMG} -c $cpuThreads -a 0 -p $PARAMS)
                # echo $OUT
                
                # get results
                CUR_COST=$(grep AVERAGE <<< "$OUT" | awk -e '{print $2}')
                echo "cost $CUR_COST" >> tmp.log
                # echo "cost $CUR_COST"
                CUR_TIME=$(grep FULL_TIME <<< "$OUT" | awk -e '{print $2}')
                echo "time $CUR_TIME" >> tmp.log
                # echo "time $CUR_TIME"

                TF=$(bc <<< "scale=8; ${CUR_COST}/${CUR_TIME}" | awk '{printf "%f", $0}')
                echo "TF $TF" >> tmp.log
                # echo "TF $TF"
                TF_LIST=$TF_LIST$TF$'\n'
                # echo "$TF_LIST"
            done
            AVRG=$(awk '{total += $1; c++} END {print total/c}' <<< "$TF_LIST")
            SSUM=$(awk -v AVRG=$AVRG '{total += ($1-AVRG)^2} END {print total}' <<< "$TF_LIST")
            # change notation from scientific to regular
            SSUM=$(sed 's/\([+-]\{0,1\}[0-9]*\.\{0,1\}[0-9]\{1,\}\)[eE]+\{0,1\}\(-\{0,1\}\)\([0-9]\{1,\}\)/(\1*10^\2\3)/g' <<<"$SSUM")
            NN=$(wc -l <<< "$TF_LIST")
            echo "AVRG: $AVRG, SSUM: $SSUM, NN: $NN" >> tmp.log
            # echo "AVRG: $AVRG, SSUM: $SSUM, NN: $NN"
            echo -n "E${E}/D${D}/T${T} TF " >> tmp.log
            echo $(bc <<< "scale=4; sqrt(${SSUM}/${NN})" | awk '{printf "%f", $0}') >> tmp.log
            echo -n $(bc <<< "scale=4; sqrt(${SSUM}/${NN})" | awk '{printf "%f", $0}')
            echo -n " "
            # echo -n "E${E}/D${D}/T${T} TF "
            # echo $(bc <<< "scale=4; sqrt(${SSUM}/${NN})" | awk '{printf "%f", $0}')
        done
        echo ""
    done
    echo ""
    echo ""
done