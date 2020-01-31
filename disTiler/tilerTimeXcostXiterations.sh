#!/bin/sh

# teste tiles regulares pequenos - correlação função de custo com tempo real (bash)

# inputs:
if [[ $# < 1 ]]; then
    echo "usage: bash regTilesTest.sh <images zip path> <exec 1 yes, 2 tiling only>"
    exit 0
fi

IMAGES_ZIP_PATH=$1
rm -rf tiles
mkdir tiles
unzip $IMAGES_ZIP_PATH
IMGS=$(readlink -f ./tiles/*)

if [[ $# == 2 ]]; then
    EXEC=$2
else
    EXEC=1
fi

THRS=( 50 100 150 200 )
ER=10
ERODE=( $ER $ER $ER $ER )
DL=10
DILATE=( $DL $DL $DL $DL )

echo "thrs/erode/dilate"
echo -n "img time   it    "
for (( p=0; p<${#THRS[@]}; p++ )); do
    echo -n "${THRS[$p]}/${ERODE[$p]}/${DILATE[$p]} "
done
echo ""

for I in ${IMGS[@]}; do
    echo -n "$(basename $I) "
    # echo "mpirun -np 2 ./iwpp ${I} -a 0"
    if [[ $EXEC == 1 ]]; then
        OUT=$(mpirun -np 2 ./iwpp ${I} -a 0)
        # echo "$OUT"
        CUR_TIME=$(grep FULL_TIME <<< "$OUT" | awk -e '{print $2}')

        # get max iteration num
        ITS=$(grep iterations <<< "$OUT" | awk -e '{print $3}')
        ITSCOUNT=$(awk -v c=0 '{c++} END {print c}' <<< "$ITS")
        if [[ ITSCOUNT == 0 ]]; then
            IT=0
        else
            IT=$(awk -v max=0 '{if($1>max){max=$1}}END{print max} ' <<< "$ITS")
        fi
    else
        CUR_TIME=0
        IT=0
    fi
    echo -n "$CUR_TIME $IT "
    
    for (( p=0; p<${#THRS[@]}; p++ )); do
       	# echo "mpirun -np 2 ./iwpp ${I} -a 0 -to -p ${THRS[$p]}/${ERODE[$p]}/${DILATE[$p]}"
       	OUT=$(mpirun -np 2 ./iwpp ${I} -to -a 0 -p ${THRS[$p]}/${ERODE[$p]}/${DILATE[$p]})
        # echo "$OUT"
    #echo $(grep curMax <<< "$OUT")
        CUR_COST=$(grep AVERAGE <<< "$OUT" | awk -e '{print $2}')
        echo -n "$CUR_COST "
    done
    echo ""
done


