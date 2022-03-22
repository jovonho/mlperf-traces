#!/bin/bash

raw_data_dir="/data/MLIO/workloads/img_seg/raw-data/kits19/data/"
preproc_data="/data/MLIO/workloads/img_seg/data/"
results_dir="/data/MLIO/workloads/img_seg/results/"

tmux new-session -d -s training
tmux send-keys -t training "sudo docker run -it --name training --ipc=host -v $raw_data_dir:/raw_data -v $preproc_data:/data -v $results_dir:/results unet3d:latest /bin/bash" C-m
tmux send-keys -t training "bash run_and_time.sh 1" C-m

exit 0

#send control C to session to kill training
tmux send-keys -t training C-c
tmux kill-session -t training

