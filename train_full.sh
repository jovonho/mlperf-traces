#!/bin/bash

cd /tracing_tools

# Force running as root
if [ "${EUID:-$(id -u)}" -ne 0 ]
then
	echo "Run script as root"
	exit -1
fi

if [ $# -lt 2 ]
then
	echo "Usage: $0 <output_dir> <num_gpus> (<experiment_name>)"
	exit -1
fi

output_dir=$1
num_gpus=$2

if [ $# -eq 3 ]
then	
	exp_name="${3}"
fi

exp_name="${exp_name}_$(date +'%Y%m%d%H%M%S')"

output_dir="${output_dir}/${exp_name}/"

if [ ! -d $output_dir ] 
then
	echo "Creating $output_dir"
	mkdir -p $output_dir
fi

# Flush filesystem caches
sync
echo 3 > /proc/sys/vm/drop_caches

sleep 5

# Delete previous app log if it exists
if [ -f "/mlcommons_training/image_segmentation/pytorch/results/unet3d.log" ]
then
	echo "Deleting old app log"
	rm /mlcommons_training/image_segmentation/pytorch/results/unet3d.log
fi

# Delete previous checkpoint file(s) if it (they) exists
if [ "$(ls /mlcommons_training/image_segmentation/pytorch/ckpts)" ]
then
	echo "Deleting old checkpoint files"
	rm /mlcommons_training/image_segmentation/pytorch/ckpts/*
fi

# Clean-up from a previous session if needed
tmux kill-session -t training

# Start a new tmux session with a live docker container inside
tmux new-session -d -s training


# Start the bpf traces, storing their pid
bpftrace trace_bio.bt -o ${output_dir}/trace_bio.out &
trace_bio_pid=$!

bpftrace trace_read.bt -o ${output_dir}/trace_read.out &
trace_read_pid=$!

bpftrace trace_write.bt -o ${output_dir}/trace_write.out &
trace_write_pid=$!

# bpftrace trace_read_addr.bt -o ${output_dir}/trace_read_addr.out &
# trace_read_addr_pid=$!

bpftrace trace_create_del.bt -o ${output_dir}/trace_create_del.out &
trace_create_del_pid=$!

bpftrace trace_openat.bt -o ${output_dir}/trace_openat.out &
trace_openat_pid=$!

bpftrace trace_close.bt -o ${output_dir}/trace_close.out &
trace_close_pid=$!

bpftrace trace_mmap.bt -o ${output_dir}/trace_mmap.out &
trace_mmap_pid=$!


# Start time alignment trace
bpftrace trace_time_align.bt -o ${output_dir}/trace_time_align.out &
trace_time_align_pid=$!

# Start the CPU and GPU traces
mpstat 1 > ${output_dir}/cpu.out &
trace_cpu_pid=$!

nvidia-smi pmon -s um -o DT -f ${output_dir}/gpu.out &		#TODO: replace with Nsight
trace_gpu_pid=$!


# Start training within the tmux session. 
tmux send-keys -t training "/mlcommons_training/image_segmentation/pytorch/start_training.sh $2" C-m

sleep 1

# Get the system-wide PID of the root process ID in the container (bash)
root_pid=$(grep -E "NSpid:[[:space:]]+[0-9]+[[:space:]]+1$" /proc/*/status 2> /dev/null | awk '{print $2}')
echo "root pid: \"$root_pid\""

while [ -z "$root_pid" ]
do
	echo "failed to get training pid, trying again"
	sleep 1
	root_pid=$(grep -E "NSpid:[[:space:]]+[0-9]+[[:space:]]+1$" /proc/*/status 2> /dev/null | awk '{print $2}')
	echo "new try: $root_pid"
done

# Attach the syscall trace to the root_process 
# It will automatically attach to all spawned child processes
#strace -T -ttt -f -p $root_pid -e 'trace=!ioctl,clock_gettime,sched_yield,nanosleep,sched_getaffinity,sched_setaffinity,futex,set_robust_list' -o ${output_dir}/strace.out &

# Sleep a bit to let training spawn all workers
sleep 120

echo "Slept 120s, collecting PIDs/TIDs and time_alignment trace"
# Save PID/TID map for later reference
ps aux -T | grep python > ${output_dir}/pids_tids.out

# Kill the time alignment trace early, 2min should be plenty
kill $trace_time_align_pid

echo "Now waiting until training completion"

# Now wait until training finishes
while kill -0 "$root_pid"; do
	sleep 5
done

# Sleep a bit more once training stops to capture full shutting down
sleep 10

# Kill the training process and the traces
# Strace was stopped when root_pid ended
./kill_training.sh
kill $trace_bio_pid
kill $trace_read_pid
# kill $trace_read_addr_pid
kill $trace_write_pid
kill $trace_create_del_pid
kill $trace_openat_pid
kill $trace_close_pid
kill $trace_mmap_pid
kill $trace_cpu_pid
kill $trace_gpu_pid

# Kill any remaining traces that didn't get killed above
remaining_traces=$(ps | grep bpf | awk '{print $1}')
for proc in $remaining_traces; 
do	
	kill $proc
done

# Copy the application log to the results directory
cp /mlcommons_training/image_segmentation/pytorch/results/unet3d.log $output_dir

# Copy the ckpt file to the results directory
cp /mlcommons_training/image_segmentation/pytorch/ckpts/ckpt_* $output_dir

# Archive the traces and copy them to discs server
tar zcvf "/results/traces_${exp_name}.tar.gz" $output_dir

#./send_to_discs.sh "/results/traces_${exp_name}.tar.gz" /data/MLIO/aws_exp_results

# rm -rf $output_dir/*


exit 0
