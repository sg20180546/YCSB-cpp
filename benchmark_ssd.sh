

BASELINE=0
SMR_ZC=1
PCA=2

OPTIONS=/home/sungjin/YCSB-cpp/rocksdb/zenfsoptions.ini
RESULT_DIR_PATH=/home/sungjin/access_testdata/YCSB

CACHESIZE=1
for i in 1 2 3
do
    for workload_type in a
    do  
        for SCHEME in   $SMR_ZC $PCA
        do
                if [ $SCHEME -eq $BASELINE ]; then
                    RESULT_PATH=${RESULT_DIR_PATH}/BASELINE_${workload_type}_${CACHESIZE}GB_${i}.txt
                    OPTIONS=/home/sungjin/YCSB-cpp/rocksdb/smr_baseline.ini
                elif [ $SCHEME -eq $SMR_ZC ]; then
                    RESULT_PATH=${RESULT_DIR_PATH}/SMR_ZC_${workload_type}_${CACHESIZE}GB_${i}.txt
                    OPTIONS=/home/sungjin/YCSB-cpp/rocksdb/smr_large_io.ini
                elif [ $SCHEME -eq $PCA ]; then
                    RESULT_PATH=${RESULT_DIR_PATH}/SMR_ZC_pca_${workload_type}_${CACHESIZE}GB_${i}.txt
                    OPTIONS=/home/sungjin/YCSB-cpp/rocksdb/smr_pca.ini
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
            while : 
                do
                sudo rm -rf /home/sungjin/log
                sudo mkdir -p /home/sungjin/log
                echo "mq-deadline" | sudo tee /sys/block/nvme1n2/queue/scheduler
                sudo /home/sungjin/ZC_SMR/rocksdb/plugin/zenfs/util/zenfs mkfs --force --enable_gc   --zbd=/nvme1n2 --aux_path=/home/sungjin/log > mkfs_log

                echo ${RESULT_PATH}
                sudo cp ${OPTIONS} /home/sungjin/log/zenfsoptions.ini

                sudo /home/sungjin/YCSB-cpp/ycsb -load -db rocksdb -P workloads/workload${workload_type} -P \
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

