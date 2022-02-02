#!/bin/bash

tmux new-session -d -s training
#tmux send-keys -t training "docker exec -it 0334b3e7e788 /bin/bash" C-m
tmux send-keys -t training "docker run -it --runtime=nvidia --name training --ipc=host -v /data/datasets/kits19/data:/raw_data -v /workloads/image_segmentation/data:/data -v /workloads/image_segmentation/results:/results unet3d_multigpu:latest /bin/bash" C-m
tmux send-keys -t training "bash run_and_time.sh 1" C-m


exit 0

#send control C to session to kill training
tmux send-keys -t training C-c
tmux kill-session -t training

