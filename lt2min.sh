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

bpftrace tracetools/cd.bt -o /data/MLIO/results/strace4/cd_trace_1worker.out &
trace_pid=$!

sleep 120

./kill_training.sh && kill $trace_pid

exit 0
# This makes the tmux session look at the script output (sent to /results/output by run_and_time.sh)
#tmux send-keys -t training "sudo docker exec -it training tail -f /results/output" C-m


# Allow a bit of time for the process to launch the python script
#exit 0

# Since the docker container is started with the command to train straight away, it will always have PID=1
# We use this PID to retrieve the equivalent PID from the point of view of the host



exit 0
# Fetch the child PID
# Note: I've noticed that some transient child processes are created when running
# This will be different depending on when it is run
python_pid=$(pgrep -P $root_pid)

sleep 1 

# This does not always run, if the python children have not had enough time to be launched.
child_pids=$(pgrep -P $python_pid)
echo "host root pid: $root_pid"
echo "host python root pid: $python_pid"
echo "host python children pids: $child_pids"

exit 0


######################

container_id=$(sudo docker ps -aqf "name=training")

docker_pid=$(sudo docker exec -t training cat /workspace/unet3d/proc.pid)

echo "docker pid: $docker_pid"

sleep 10

root_pid=`grep -E "NSpid:[[:space:]]+[0-9]+[[:space:]]+$docker_pid$" /proc/*/status 2> /dev/null | awk '{print $2}'`
#host_pid=`grep NSpid.*$docker_pid /proc/*/status 2> /dev/null`

