

BASELINE=0
ZEUFS=1

OPTIONS=/home/femu/YCSB-cpp/rocksdb/zenfsoptions.ini
RESULT_DIR_PATH=/home/femu/FAST_testdata/YCSB

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
                    RESULT_PATH=${RESULT_DIR_PATH}/LIZA_${WORKLOAD_TYPE}_LSE_${i}.txt
                    OPTIONS=/home/femu/YCSB-cpp/rocksdb/FAST_baseline.ini 
                elif [ $SCHEME -eq $ZEUFS ]; then
                    RESULT_PATH=${RESULT_DIR_PATH}/LIZA_${WORKLOAD_TYPE}_ZEUFS_${i}.txt
                    OPTIONS=/home/femu/YCSB-cpp/rocksdb/FAST_motiv_zonereset.ini
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
                /home/femu/zone_reset_all 0 25
                sudo rm -rf /home/femu/log
                sudo mkdir -p /home/femu/log
                echo "mq-deadline" | sudo tee /sys/block/nvme0n1/queue/scheduler
                
                
                sudo /home/femu/CAZAandZACA/rocksdb/plugin/zenfs/util/zenfs mkfs --force --enable_gc   --zbd=/nvme0n1 --aux_path=/home/femu/log > mkfs_log

                echo ${RESULT_PATH}
                sudo cp ${OPTIONS} /home/femu/log/zenfsoptions.ini

                sudo /home/femu/YCSB-cpp/ycsb -run -db rocksdb -P workloads/workload_${WORKLOAD_TYPE} -P \
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

sudo /home/femu/access_testdata/sendresultmail

