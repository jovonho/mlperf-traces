#!/bin/bash

if [ $# -ne 1 ]; then
	echo "Usage $0 outputfile"
	exit 0
fi

echo "Recording all syscalls by python processes in the background for 60s"
bpftrace -e 'tracepoint:syscalls:sys_enter* /comm=="python"/ { @[probe] = count(); }' -o "$1_bg" &
pid=$!
sleep 60

echo "Stopping trace (pid=$pid)"
while `kill -SIGINT $pid`; do
	echo "waiting for trace to stop"
	sleep 5
done
echo "Background measurement done. Starting real tracing."


echo "Recording all syscalls by python processes while training on 8 GPUs"
bpftrace -e 'tracepoint:syscalls:sys_enter* /comm=="python"/ { @[probe] = count(); }' -o "$1_8GPUS" &
pid=$!

echo "Starting training"
./start_training_8GPUs.sh &

sleep 60

echo "Stopping training"
./stop_training.sh &


echo "Stopping trace (pid=$pid)"
while `kill -SIGINT $pid`; do
     echo "waiting for trace to stop"
     sleep 5
done
echo "done"


echo "Recording all syscalls by python processes while training on 1 GPU"
bpftrace -e 'tracepoint:syscalls:sys_enter* /comm=="python"/ { @[probe] = count(); }' -o "$1_1GPU" &
pid=$!

echo "Starting training"
./start_training_1GPU.sh &

sleep 60

echo "Stopping training"
./stop_training.sh &


echo "Stopping trace (pid=$pid)"
while `kill -SIGINT $pid`; do
    echo "waiting for trace to stop"
    sleep 5
done
echo "done"


echo "Recording all syscalls by python processes while training on CPU"
bpftrace -e 'tracepoint:syscalls:sys_enter* /comm=="python"/ { @[probe] = count(); }' -o "$1_CPU" &
pid=$!

echo "Starting training"
./start_training_CPU.sh &

sleep 60

echo "Stopping training"
./stop_training.sh &


echo "Stopping trace (pid=$pid)"
while kill -SIGINT $pid; do
    echo "waiting for trace to stop"
    sleep 5
done
echo "done"

