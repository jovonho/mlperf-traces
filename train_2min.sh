#!/bin/bash

# Force running as root
if [ "${EUID:-$(id -u)}" -ne 0 ]
then
	echo "Run script as root"
	exit -1
fi

if [ $# -lt 2 ]
then
	echo "Usage: $0 <output_dir> <num_gpus>"
	exit -1
fi

output_dir=$1

# Clean-up from a previous session if needed
tmux kill-session -t training

# Start a new tmux session with a live docker container inside
tmux new-session -d -s training


# Start the bpf traces, storing their pid
bpftrace trace_vfs.bt -o ${output_dir}/trace_vfs.out &
trace_vfs_pid=$!

bpftrace trace_bio.bt -o ${output_dir}/trace_bio.out &
trace_bio_pid=$!

mpstat 1 > ${output_dir}/cpu.out &
trace_cpu_pid=$!

nvidia-smi pmon -s um -o DT -f ${output_dir}/gpu.out &
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
	root_pid=$(grep -E "NSpid:[[:space:]]+[0-9]+[[:space:]]+1[0-9]$" /proc/*/status 2> /dev/null | awk '{print $2}')
	echo "new try: $root_pid"
done

# Attach strace to it (will automatically attach to all child processes)
strace -ttt -f -p $root_pid -e 'trace=!ioctl,clock_gettime,sched_yield,nanosleep,sched_getaffinity,sched_setaffinity,futex,set_robust_list' -o ${output_dir}/strace.out &

sleep 120

# Kill the training process and the traces
./kill_training.sh
kill $trace_vfs_pid
kill $trace_bio_pid
kill $trace_cpu_pid
kill $trace_gpu_pid

exit 0
