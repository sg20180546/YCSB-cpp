BASELINE=0
ZEUFS=2

OPTIONS=/home/femu/YCSB-cpp/rocksdb/zenfsoptions.ini
RESULT_DIR_PATH=/home/femu/FAST_testdata/YCSB

# CACHESIZE=4

# PHASE=load

SIZE=67108864

A="a"
SCANWRITERANDOM="scanwriterandom"

for i in 1 2 3
do
    for WORKLOAD_TYPE in fillrandom
    do  
        for SCHEME in $BASELINE
        do
                if [ $SCHEME -eq $BASELINE ]; then
                    RESULT_PATH=${RESULT_DIR_PATH}/LIZA_${WORKLOAD_TYPE}_LME4_${i}.txt
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


                 sudo /home/femu/CAZAandZACA/rocksdb/db_bench \
                         -num=${SIZE} -benchmarks="fillrandom,stats" --fs_uri=zenfs://dev:nvme0n1 -statistics  -value_size=1024 \
                          -max_background_compactions=2   -max_background_flushes=2 -subcompactions=4  \
                          -histogram -seed=1699101730035899  -wait_for_compactions=false -enable_intraL0_compaction=false \
                        -reset_scheme=${SCHEME} -tuning_point=100 -partial_reset_scheme=1 -disable_wal=false -zc=30 -until=30 \
                        -allocation_scheme=0  -compaction_scheme=0 -level0_stop_writes_trigger=8 \
                         -max_compaction_start_level=5 -input_aware_scheme=0 \
                        -max_compaction_kick=0 -default_extent_size=1048576 -async_zc_enabled=0 > ${RESULT_DIR_PATH}/tmp



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

