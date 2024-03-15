

BASELINE=0
OPENPRI=1
# ZC_NOAWARE=3

OPTIONS=/home/sungjin/YCSB-cpp/rocksdb/zenfsoptions.ini
RESULT_DIR_PATH=/home/sungjin/access_testdata/YCSB2


CACHESIZE=4
# load or run
PHASE=load

for i in 20 21 22
do
    for workload_type in a
    do  
        for SCHEME in  $OPENPRI $BASELINE
        do
                if [ $SCHEME -eq $BASELINE ]; then
                    RESULT_PATH=${RESULT_DIR_PATH}/BASELINE_${workload_type}_${CACHESIZE}GB_${i}.txt
                    OPTIONS=/home/sungjin/YCSB-cpp/rocksdb/ssd_baseline.ini
                elif [ $SCHEME -eq $OPENPRI ]; then
                    RESULT_PATH=${RESULT_DIR_PATH}/OPENPRI_${workload_type}_${CACHESIZE}GB_${i}.txt
                    OPTIONS=/home/sungjin/YCSB-cpp/rocksdb/ssd_openpri.ini
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
                sudo /home/sungjin/ZC_SSD/rocksdb/plugin/zenfs/util/zenfs mkfs --force --enable_gc   --zbd=/nvme1n2 --aux_path=/home/sungjin/log > mkfs_log

                echo ${RESULT_PATH}
                sudo cp ${OPTIONS} /home/sungjin/log/zenfsoptions.ini

                sudo /home/sungjin/YCSB-cpp/ycsb -${PHASE} -db rocksdb -P workloads/workload${workload_type} -P \
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

echo "all done"

sudo /home/sungjin/access_testdata/sendresultmail

