#!/bin/bash

# Force running as root
if [ "${EUID:-$(id -u)}" -ne 0 ]
then
	sudo su -
fi

# Clean-up from a previous session if needed
tmux kill-session -t training

# Start a new tmux session 
tmux new-session -d -s training 

# Start the bpf traces, storing their pid
bpftrace trace_vfs.bt -o ${output_dir}/trace_vfs.out &
trace_vfs_pid=$!

bpftrace trace_bio.bt -o ${output_dir}/trace_bio.out &
trace_bio_pid=$!

# Start training within the tmux session.
# Docker runs in detached mode, so in the background 
tmux send-keys -t training "sudo docker exec -it -t training /bin/bash run_and_time.sh 1" C-m

sleep 1

# Get the training process root pid
root_pid=`grep -E "NSpid:[[:space:]]+[0-9]+[[:space:]]+1[0-9]$" /proc/*/status 2> /dev/null | awk '{print $2}'`
echo $root_pid

# Attach strace to it (will automatically attach to all child processes)
strace -ttt -f -p $root_pid -e 'trace=!sched_yield,nanosleep,sched_getaffinity,sched_setaffinity,futex,set_robust_list' -o /data/MLIO/results/strace4/strace_1worker.out &

sleep 120

# Kill the training process and the traces
./kill_training.sh
kill $trace_vfs_pid
kill $trace_vio_pid

exit 0
