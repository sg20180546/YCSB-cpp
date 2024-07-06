

BASELINE=0
ZEUFS=1

OPTIONS=/home/micron/YCSB-cpp/rocksdb/zenfsoptions.ini
RESULT_DIR_PATH=/home/micron/FAST_testdata/YCSB

CACHESIZE=4

# PHASE=load

A="a"
SCANWRITERANDOM="scanwriterandom"

for i in 1 2 3
do
    for WORKLOAD_TYPE in zipfian latest uniform
    do  
        for SCHEME in $BASELINE
        do
                if [ $SCHEME -eq $BASELINE ]; then
                    RESULT_PATH=${RESULT_DIR_PATH}/CAZA_${WORKLOAD_TYPE}_LME4_${i}.txt
                    OPTIONS=/home/micron/YCSB-cpp/rocksdb/FAST_baseline_cosmos.ini 
                elif [ $SCHEME -eq $ZEUFS ]; then
                    RESULT_PATH=${RESULT_DIR_PATH}/CAZA_${WORKLOAD_TYPE}_ZEUFS_${i}.txt
                    OPTIONS=/home/micron/YCSB-cpp/rocksdb/FAST_FAR_cosmos.ini
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
                sudo /home/micron/zone_reset_all 0 20
                sudo rm -rf /home/micron/log
                sudo mkdir -p /home/micron/log
                echo "mq-deadline" | sudo tee /sys/block/nvme0n1/queue/scheduler
                
                
                sudo /home/micron/CAZAandZACA/rocksdb/plugin/zenfs/util/zenfs mkfs --force --enable_gc   --zbd=/nvme0n1 --aux_path=/home/micron/log > mkfs_log

                echo ${RESULT_PATH}
                sudo cp ${OPTIONS} /home/micron/log/zenfsoptions.ini

                sudo /home/micron/YCSB-cpp/ycsb -load -db rocksdb -P workloads/workload_${WORKLOAD_TYPE} -P \
                        rocksdb/rocksdb.properties -s > ${RESULT_DIR_PATH}/tmp
                
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

echo "all done"

sudo /home/micron/access_testdata/sendresultmail

