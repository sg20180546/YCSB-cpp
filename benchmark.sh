LIZA=0
LIZACA=1
CAZA=2
CAZACA=3
OPTIONS=/home/femu/YCSB-cpp/rocksdb/zenfsoptions.ini
RESULT_DIR_PATH=/home/femu/access_testdata/YCSB
for i in 1
do
    for workload_type in a d e
    do  
        for SCHEME in $LIZA $LIZACA $CAZA $CAZACA
        do
                if [ $SCHEME -eq $LIZA ]; then
                    RESULT_PATH=${RESULT_DIR_PATH}/A_${workload_type}_LIZA_${i}_timelapse.txt
                    OPTIONS=/home/femu/YCSB-cpp/rocksdb/lizaoption.ini
                elif [ $SCHEME -eq $LIZACA ]; then
                    RESULT_PATH=${RESULT_DIR_PATH}/B_${workload_type}_LIZACA_${i}_timelapse.txt
                    OPTIONS=/home/femu/YCSB-cpp/rocksdb/lizacaoption.ini
                elif [ $SCHEME -eq $CAZA ]; then
                    RESULT_PATH=${RESULT_DIR_PATH}/C_${workload_type}_CAZA_${i}_timelapse.txt
                    OPTIONS=/home/femu/YCSB-cpp/rocksdb/cazaoption.ini
                elif [ $SCHEME -eq $CAZACA ]; then
                    RESULT_PATH=${RESULT_DIR_PATH}/D_${workload_type}_CAZACA_${i}_timelapse.txt
                    OPTIONS=/home/femu/YCSB-cpp/rocksdb/cazacaoption.ini
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
                sudo rm -rf /home/femu/log
                sudo mkdir -p /home/femu/log
                echo "mq-deadline" | sudo tee /sys/block/nvme0n1/queue/scheduler
                sudo /home/femu/CAZA/rocksdb/plugin/zenfs/util/zenfs mkfs --force --enable_gc   --zbd=/nvme0n1 --aux_path=/home/femu/log > mkfs_log

                echo ${RESULT_PATH}
                sudo cp ${OPTIONS} /home/femu/log/zenfsoptions.ini

                sudo /home/femu/YCSB-cpp/ycsb -load -db rocksdb -P workloads/workload${workload_type} -P \
                        rocksdb/rocksdb.properties -s > ${RESULT_DIR_PATH}/tmp
                
                if grep -q "total samezone score" ${RESULT_DIR_PATH}/tmp; then
                    cat ${RESULT_DIR_PATH}/tmp > ${RESULT_PATH}
                    rm -rf ${RESULT_DIR_PATH}/tmp
                    break
                else
                    cat ${RESULT_DIR_PATH}/tmp > ${RESULT_DIR_PATH}/failed
                    sleep 5
                fi
            done
        done
    done
done

echo "all done"

sudo /home/femu/access_testdata/sendresultmail

