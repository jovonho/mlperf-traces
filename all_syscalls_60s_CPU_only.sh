#!/bin/bash

# Get a background reading in case other python processes are running
echo "Measuring background activity for 60s..."
sudo bpftrace -e 'tracepoint:syscalls:sys_enter* /comm=="python"/ { @[probe] = count(); }' -o ./syscalls_bg_60s.txt &
pid=$!
sleep 60

echo "Stopping trace (pid=$pid)"
sudo pkill -SIGINT -P $pid &

# Sleep enough time for the trace to finish and save its output
sleep 15
echo "Done..."

# Start the training and capture all syscalls again
echo "Launching training"
./launch_training.sh & 2>/dev/null

echo "Measuring all syscalls called by python processes for 60s..."
sudo bpftrace -e 'tracepoint:syscalls:sys_enter* /comm=="python"/ { @[probe] = count(); }' -o ./syscalls_60s.txt &
pid=$!
sleep 60

echo "Stopping training"
./kill_training.sh &

sleep 5

echo "Stopping trace (pid=$pid)"
sudo pkill -SIGINT -P $pid &

sleep 15
echo "Trace completed"

