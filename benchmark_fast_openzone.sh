

BASELINE=0
ZEUFS_LOG=1
ZEUFS_LINEAR=2
ZEUFS_EXP=3

OPTIONS=/home/micron/YCSB-cpp/rocksdb/zenfsoptions.ini
RESULT_DIR_PATH=/home/micron/FAST_testdata/YCSB_open

CACHESIZE=4
NVME=nvme0n1

# PHASE=load

A="a"
SCANWRITERANDOM="scanwriterandom"
T=90
for SCHEME in $ZEUFS_LINEAR $BASELINE
do
    for i in 1
    do
        for WORKLOAD_TYPE in uniform
        do  
            for O in 160 80 40 20 10
            do
                    if [ $SCHEME -eq $BASELINE ]; then
                        RESULT_PATH=${RESULT_DIR_PATH}/CAZA_${WORKLOAD_TYPE}_LSE_${O}_${i}.txt
                        OPTIONS=/home/micron/YCSB-cpp/rocksdb/FAST_openzone.ini
                        sed -i "s/^  tuning_point=.*/  tuning_point=${T}/" $OPTIONS
                        sed -i "s/^  reset_scheme=.*/  reset_scheme=0/" $OPTIONS
                        sed -i "s/^  pca_selection=.*/  pca_selection=${O}/" $OPTIONS
                    elif [ $SCHEME -eq $ZEUFS_LOG ]; then
                        RESULT_PATH=${RESULT_DIR_PATH}/CAZA_${WORKLOAD_TYPE}_ZEUFS_LOG_${T}_${O}_${i}.txt
                        OPTIONS=/home/micron/YCSB-cpp/rocksdb/FAST_openzone.ini
                        sed -i "s/^  tuning_point=.*/  tuning_point=${T}/" $OPTIONS
                        sed -i "s/^  reset_scheme=.*/  reset_scheme=3/" $OPTIONS
                        sed -i "s/^  pca_selection=.*/  pca_selection=${O}/" $OPTIONS
                    elif [ $SCHEME -eq $ZEUFS_LINEAR ]; then
                        RESULT_PATH=${RESULT_DIR_PATH}/CAZA_${WORKLOAD_TYPE}_ZEUFS_LINEAR_${T}_${O}_${i}.txt
                        OPTIONS=/home/micron/YCSB-cpp/rocksdb/FAST_openzone.ini
                        sed -i "s/^  tuning_point=.*/  tuning_point=${T}/" $OPTIONS
                        sed -i "s/^  reset_scheme=.*/  reset_scheme=4/" $OPTIONS
                        sed -i "s/^  pca_selection=.*/  pca_selection=${O}/" $OPTIONS
                    elif [ $SCHEME -eq $ZEUFS_EXP ]; then
                        RESULT_PATH=${RESULT_DIR_PATH}/CAZA_${WORKLOAD_TYPE}_ZEUFS_EXP_${T}_${O}_${i}.txt
                        OPTIONS=/home/micron/YCSB-cpp/rocksdb/FAST_openzone.ini
                        sed -i "s/^  tuning_point=.*/  tuning_point=${T}/" $OPTIONS
                        sed -i "s/^  reset_scheme=.*/  reset_scheme=9/" $OPTIONS
                        sed -i "s/^  pca_selection=.*/  pca_selection=${O}/" $OPTIONS
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
                    echo "mq-deadline" | sudo tee /sys/block/${NVME}/queue/scheduler > /home/micron/tmp2
                    
                    
                    sudo /home/micron/CAZAandZACA/rocksdb/plugin/zenfs/util/zenfs mkfs --force --enable_gc \
                    --zbd=/${NVME} --aux_path=/home/micron/log > /home/micron/tmp2

                    echo ${RESULT_PATH}
                    sudo cp ${OPTIONS} /home/micron/log/zenfsoptions.ini

                    sudo /home/micron/YCSB-cpp/ycsb -load -db rocksdb -P workloads/workload_${WORKLOAD_TYPE} -P rocksdb/rocksdb.properties -s > ${RESULT_DIR_PATH}/tmp
                    
                    if grep -q "samezone score" ${RESULT_DIR_PATH}/tmp; then
                        cat ${RESULT_DIR_PATH}/tmp > ${RESULT_PATH}
                        rm -rf ${RESULT_DIR_PATH}/tmp
                        # DUMMY
                        sudo /home/micron/zns_utilities/dummy 999 999
                        break
                    else
                        cat ${RESULT_DIR_PATH}/tmp > ${RESULT_DIR_PATH}/failed
                        sudo /home/micron/zns_utilities/dummy 999 999
                        break
                        # sleep 5
                    fi
                done
            done
        done
    done
done

echo "all done"

sudo /home/micron/access_testdata/sendresultmail

