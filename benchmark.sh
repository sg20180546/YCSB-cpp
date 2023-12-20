for i in 1 2 3
do
    for workload_type in a b c d e f
    do
        sudo rm -rf ~/log
        sudo mkdir -p ~/log
        echo "mq-deadline" | sudo tee /sys/block/nvme0n1/queue/scheduler
        sudo /home/femu/CAZA/rocksdb/plugin/zenfs/util/zenfs mkfs --force --enable_gc   --zbd=/nvme0n1 --aux_path=/home/femu/log
        sudo cp /home/femu/YCSB-cpp/rocksdb/zenfsoptions.ini ~/log/zenfsoptions.ini
        sudo /home/femu/YCSB-cpp/ycsb -load -run -db rocksdb -P workloads/workload${workload_type} -P \
                 rocksdb/rocksdb.properties -s > /home/femu/access_testdata/YCSB/CAZACA_${workload_type}_i
    done
done

