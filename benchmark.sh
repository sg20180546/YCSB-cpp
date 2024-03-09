

BASELINE=0
ZC_SEPERATION=1
ZC_SEPERATION_INVALID=2

OPTIONS=/home/sungjin/YCSB-cpp/rocksdb/zenfsoptions.ini
RESULT_DIR_PATH=/home/sungjin/access_testdata/YCSB

CACHESIZE=4

# PHASE=load

A="a"
SCANWRITERANDOM="scanwriterandom"

for i in 1 2 3
do
    for WORKLOAD_TYPE in insert90
    do  
        for SCHEME in $BASELINE $ZC_SEPERATION_INVALID $ZC_SEPERATION
        do
                if [ $SCHEME -eq $BASELINE ]; then
                    RESULT_PATH=${RESULT_DIR_PATH}/BASELINE_${WORKLOAD_TYPE}_${CACHESIZE}GB_${i}.txt
                    OPTIONS=/home/sungjin/YCSB-cpp/rocksdb/smr_baseline.ini
                elif [ $SCHEME -eq $ZC_SEPERATION ]; then
                    RESULT_PATH=${RESULT_DIR_PATH}/SEPERATION_${WORKLOAD_TYPE}_${CACHESIZE}GB_${i}.txt
                    OPTIONS=/home/sungjin/YCSB-cpp/rocksdb/smr_sep.ini
                elif [ $SCHEME -eq $ZC_SEPERATION_INVALID ]; then
                    RESULT_PATH=${RESULT_DIR_PATH}/SEPERATION_INVALID_${WORKLOAD_TYPE}_${CACHESIZE}GB_${i}.txt
                    OPTIONS=/home/sungjin/YCSB-cpp/rocksdb/smr_sep_invalid.ini
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
                sudo rm -rf /home/sungjin/log
                sudo mkdir -p /home/sungjin/log
                echo "mq-deadline" | sudo tee /sys/block/sdb/queue/scheduler
                sudo /home/sungjin/ZC_SMR/rocksdb/plugin/zenfs/util/zenfs mkfs --force --enable_gc   --zbd=/sdb --aux_path=/home/sungjin/log > mkfs_log

                echo ${RESULT_PATH}
                sudo cp ${OPTIONS} /home/sungjin/log/zenfsoptions.ini

                sudo /home/sungjin/YCSB-cpp/ycsb -load -run -db rocksdb -P workloads/workload${WORKLOAD_TYPE} -P \
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

sudo /home/sungjin/access_testdata/sendresultmail

