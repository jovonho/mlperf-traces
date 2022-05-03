#!/bin/bash

sudo docker kill training
sudo docker rm training

tmux kill-session -t training

