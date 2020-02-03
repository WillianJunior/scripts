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

THRS=( 100 150 )
# ERODE=( 2 )
# DILATE=( 2 )
ERODE=( 2 4 8 10 )
DILATE=( 2 4 8 10 )

REPS=3

echo "thrs/erode/dilate"
echo -n "img time time_error it "
for (( T=0; T<${#THRS[@]}; T++ )); do
    for (( E=0; E<${#ERODE[@]}; E++ )); do
        for (( D=0; D<${#DILATE[@]}; D++ )); do
            echo -n "${THRS[$T]}/${ERODE[$E]}/${DILATE[$D]} "
        done
    done
done
echo ""

for I in ${IMGS[@]}; do
    # initial test: exectime and iterations
    echo -n "$(basename $I) "
    if [[ $EXEC == 1 ]]; then
        SUM_TIME=0
        ERR_LIST=()
        for (( R=0; R<REPS; R++ )); do
            OUT=$(mpirun -np 2 ./iwpp ${I} -a 0)
            # echo "$OUT"
            CUR_TIME=$(grep FULL_TIME <<< "$OUT" | awk -e '{print $2}')

            SUM_TIME=$(($SUM_TIME + $CUR_TIME))
            # ERR_LIST=$ERR_LIST$CUR_TIME$'\n'
            ERR_LIST[${R}]=$CUR_TIME

            # get max iteration num
            ITS=$(grep iterations <<< "$OUT" | awk -e '{print $3}')
            ITSCOUNT=$(awk -v c=0 '{c++} END {print c}' <<< "$ITS")
            if [[ ITSCOUNT == 0 ]]; then
                IT=0
            else
                IT=$(awk -v max=0 '{if($1>max){max=$1}}END{print max} ' <<< "$ITS")
            fi
        done
        CUR_TIME=$(($SUM_TIME/$REPS))

        # calculate mesure error
        # ERR=$(awk -v errs=0 -v AVRG=$CUR_TIME '{errs += bc <<< "sqrt(pow($1-AVRG,2))"; c++} END {print total/c c}' <<< "$ERR_LIST")

        SUM_ERR=0
        for (( E=0; E<${#ERR_LIST[@]}; E++ )); do
            ERR=$(bc <<< "sqrt((${ERR_LIST[${E}]}-${CUR_TIME})^2)")
            ERR_LIST2[${E}]=$ERR_LIST2$ERR$'\n'
            SUM_ERR=$(($SUM_ERR+$ERR))
        done
    else
        CUR_TIME=0
        SUM_ERR=0
        IT=0
    fi
    echo -n $CUR_TIME $SUM_ERR $IT" "

    # get cost for each parameters set
    for (( T=0; T<${#THRS[@]}; T++ )); do
        for (( E=0; E<${#ERODE[@]}; E++ )); do
            for (( D=0; D<${#DILATE[@]}; D++ )); do
               	OUT=$(mpirun -np 2 ./iwpp ${I} -to -a 0 -p ${THRS[$T]}/${ERODE[$E]}/${DILATE[$D]})
                # echo "$OUT"
                #echo $(grep curMax <<< "$OUT")
                CUR_COST=$(grep AVERAGE <<< "$OUT" | awk -e '{print $2}')
                echo -n $CUR_COST" "
            done
        done
    done

    echo ""
done


