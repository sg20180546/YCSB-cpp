

BASELINE=0
ZEUFS_LOG=1
ZEUFS_LINEAR=2
ZEUFS_EXP=3



OPTIONS=/home/femu/YCSB-cpp/rocksdb/zenfsoptions.ini
RESULT_DIR_PATH=/home/femu/FAST_testdata/YCSB

CACHESIZE=4

# PHASE=load

A="a"
SCANWRITERANDOM="scanwriterandom"




# 옵션 파일 경로
# OPTION_FILE="options.txt"

# # 변경할 값들
# advise_random_on_open="false"
# reset_scheme="3"
# tuning_point="150"
# partial_reset_scheme="0"
# zc="50"

# # 옵션 파일 백업
# cp $OPTION_FILE ${OPTION_FILE}.bak

# # 옵션 파일 수정
# sed -i "s/^advise_random_on_open=.*/advise_random_on_open=${advise_random_on_open}/" $OPTION_FILE
# sed -i "s/^reset_scheme=.*/reset_scheme=${reset_scheme}/" $OPTION_FILE
# sed -i "s/^tuning_point=.*/tuning_point=${tuning_point}/" $OPTION_FILE
# sed -i "s/^partial_reset_scheme=.*/partial_reset_scheme=${partial_reset_scheme}/" $OPTION_FILE
# sed -i "s/^zc=.*/zc=${zc}/" $OPTION_FILE

# echo "Options updated successfully."

for T in 100
do
    for i in 1 2 3
    do
        for WORKLOAD_TYPE in uniform zipfian latest
        do
            for SCHEME in $ZEUFS_EXP $ZEUFS_LINEAR $ZEUFS_LOG
            do
                    if [ $SCHEME -eq $BASELINE ]; then
                        RESULT_PATH=${RESULT_DIR_PATH}/CAZA_${WORKLOAD_TYPE}_SME4_${i}.txt
                        OPTIONS=/home/femu/YCSB-cpp/rocksdb/FAST_baseline_small.ini 
                    elif [ $SCHEME -eq $ZEUFS_LOG ]; then
                        RESULT_PATH=${RESULT_DIR_PATH}/CAZA_${WORKLOAD_TYPE}_ZEUFS_LOG_${T}_${i}.txt
                        OPTIONS=/home/femu/YCSB-cpp/rocksdb/FAST_FAR.ini
                        sed -i "s/^  tuning_point=.*/  tuning_point=${T}/" $OPTIONS
                        sed -i "s/^  reset_scheme=.*/  reset_scheme=3/" $OPTIONS
                    elif [ $SCHEME -eq $ZEUFS_LINEAR ]; then
                        RESULT_PATH=${RESULT_DIR_PATH}/CAZA_${WORKLOAD_TYPE}_ZEUFS_LINEAR_${T}_${i}.txt
                        OPTIONS=/home/femu/YCSB-cpp/rocksdb/FAST_FAR.ini
                        sed -i "s/^  tuning_point=.*/  tuning_point=${T}/" $OPTIONS
                        sed -i "s/^  reset_scheme=.*/  reset_scheme=4/" $OPTIONS
                    elif [ $SCHEME -eq $ZEUFS_EXP ]; then
                        RESULT_PATH=${RESULT_DIR_PATH}/CAZA_${WORKLOAD_TYPE}_ZEUFS_EXP_${T}_${i}.txt
                        OPTIONS=/home/femu/YCSB-cpp/rocksdb/FAST_FAR.ini
                        sed -i "s/^  tuning_point=.*/  tuning_point=${T}/" $OPTIONS
                        sed -i "s/^  reset_scheme=.*/  reset_scheme=9/" $OPTIONS
                    else  
                        echo "error"
                    fi
                if [ -f ${RESULT_PATH} ]; then
                    echo "already $RESULT_PATH exists"
                    sleep 5
                    continue
                fi
                # if [ "$WORKLOAD_TYPE" = "$A" ]; then
                #     PHASE=load
                # else
                #     PHASE=run
                # fi

                while : 
                    do
                    sudo /home/femu/zone_reset_all 0 20 > /home/femu/tmp
                    sudo rm -rf /home/femu/log
                    sudo mkdir -p /home/femu/log
                    echo "mq-deadline" | sudo tee /sys/block/nvme0n1/queue/scheduler
                    
                    
                    sudo /home/femu/CAZAandZACA/rocksdb/plugin/zenfs/util/zenfs mkfs --force --enable_gc \
                      --zbd=/nvme0n1 --aux_path=/home/femu/log > /home/femu/tmp

                    echo ${RESULT_PATH}
                    sudo cp ${OPTIONS} /home/femu/log/zenfsoptions.ini

                    sudo /home/femu/YCSB-cpp/ycsb -load -db rocksdb -P workloads/workload_${WORKLOAD_TYPE} -P \
                            rocksdb/rocksdb.properties2 -s > ${RESULT_DIR_PATH}/tmp
                    
                    if grep -q "samezone score" ${RESULT_DIR_PATH}/tmp; then
                        cat ${RESULT_DIR_PATH}/tmp > ${RESULT_PATH}
                        rm -rf ${RESULT_DIR_PATH}/tmp
                        break
                    else
                        cat ${RESULT_DIR_PATH}/tmp > ${RESULT_DIR_PATH}/failed
                        sleep 5
                        # break
                    fi
                done
            done
        done
    done
done

echo "all done"

sudo /home/femu/access_testdata/sendresultmail

