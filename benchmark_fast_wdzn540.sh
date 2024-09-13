

BASELINE=0
ZEUFS_LOG=1
ZEUFS_LINEAR=2
ZEUFS_EXP=3

OPTIONS=/home/micron/YCSB-cpp/rocksdb/zenfsoptions.ini
RESULT_DIR_PATH=/home/micron/FAST_testdata/YCSB_wd

CACHESIZE=4

# PHASE=load

A="a"
SCANWRITERANDOM="scanwriterandom"
for T in 110
do
    for i in 31 32 33
    do
        for WORKLOAD_TYPE in uniform
        do  
            for SCHEME in  $ZEUFS_LINEAR $BASELINE
            do
                    if [ $SCHEME -eq $BASELINE ]; then
                        RESULT_PATH=${RESULT_DIR_PATH}/CAZA_${WORKLOAD_TYPE}_LSE_${i}.txt
                        OPTIONS=/home/micron/YCSB-cpp/rocksdb/FAST_baseline_wd.ini 
                    elif [ $SCHEME -eq $ZEUFS_LOG ]; then
                        RESULT_PATH=${RESULT_DIR_PATH}/CAZA_${WORKLOAD_TYPE}_ZEUFS_LOG_${T}_${i}.txt
                        OPTIONS=/home/micron/YCSB-cpp/rocksdb/FAST_FAR_wd.ini
                        sed -i "s/^  tuning_point=.*/  tuning_point=${T}/" $OPTIONS
                        sed -i "s/^  reset_scheme=.*/  reset_scheme=3/" $OPTIONS
                    elif [ $SCHEME -eq $ZEUFS_LINEAR ]; then
                        RESULT_PATH=${RESULT_DIR_PATH}/CAZA_${WORKLOAD_TYPE}_ZEUFS_LINEAR_${T}_${i}.txt
                        OPTIONS=/home/micron/YCSB-cpp/rocksdb/FAST_FAR_wd.ini
                        sed -i "s/^  tuning_point=.*/  tuning_point=${T}/" $OPTIONS
                        sed -i "s/^  reset_scheme=.*/  reset_scheme=4/" $OPTIONS
                    elif [ $SCHEME -eq $ZEUFS_EXP ]; then
                        RESULT_PATH=${RESULT_DIR_PATH}/CAZA_${WORKLOAD_TYPE}_ZEUFS_EXP_${T}_${i}.txt
                        OPTIONS=/home/micron/YCSB-cpp/rocksdb/FAST_FAR_wd.ini
                        sed -i "s/^  tuning_point=.*/  tuning_point=${T}/" $OPTIONS
                        sed -i "s/^  reset_scheme=.*/  reset_scheme=9/" $OPTIONS
                    else  
                        echo "error"
                    fi
                if [ -f ${RESULT_PATH} ]; then
                    echo "already $RESULT_PATH exists"
                    # sleep 30
                    sleep 5
                    continue
                    # break
                fi
                # if [ "$WORKLOAD_TYPE" = "$A" ]; then
                #     PHASE=load
                # else
                #     PHASE=run
                # fi

                while : 
                    do
                    sudo /home/micron/zone_reset_all 0 100 > /home/micron/tmp
                    sudo rm -rf /home/micron/log
                    sudo mkdir -p /home/micron/log
                    echo "mq-deadline" | sudo tee /sys/block/nvme0n2/queue/scheduler
                    
                    
                    sudo /home/micron/CAZAandZACA/rocksdb/plugin/zenfs/util/zenfs mkfs --force --enable_gc \
                    --zbd=/nvme0n2 --aux_path=/home/micron/log > /home/micron/tmp2

                    echo ${RESULT_PATH}
                    sudo cp ${OPTIONS} /home/micron/log/zenfsoptions.ini

                    sudo /home/micron/YCSB-cpp/ycsb -load -db rocksdb -P workloads/workload_${WORKLOAD_TYPE} -P rocksdb/rocksdb.properties -s > ${RESULT_DIR_PATH}/tmp
                    
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

sudo /home/micron/access_testdata/sendresultmail

