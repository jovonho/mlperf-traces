#!/bin/bash

# Clean-up from a previous session
#sudo docker kill training
#sudo docker rm training
tmux kill-session -t training

# Start a new tmux session 
tmux new-session -d -s training 

sleep 1

# Start training within the tmux session.
# Docker runs in detached mode, so in the background 
tmux send-keys -t training "sudo docker exec -it -t training /bin/bash run_and_time.sh 1" C-m

sleep 1
#tmux send-keys -t training "bash run_and_time.sh 1" C-m

#sleep 2

#pid=$(sudo docker exec training cat /workspace/unet3d/proc.pid)
#echo $pid

#sleep 1
#sudo docker exec training ps aux


root_pid=`grep -E "NSpid:[[:space:]]+[0-9]+[[:space:]]+1[0-9]$" /proc/*/status 2> /dev/null | awk '{print $2}'`
echo $root_pid

strace -ttt -f -p $root_pid -e 'trace=!sched_yield,nanosleep,sched_getaffinity,sched_setaffinity,futex,set_robust_list' -o /data/MLIO/results/strace4/strace_1worker.out &

bpftrace cd.bt -o /data/MLIO/results/strace4/cd_trace_1worker.out &
trace_pid=$!

sleep 120

./kill_training.sh && kill $trace_pid

exit 0
