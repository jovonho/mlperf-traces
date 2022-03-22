#!/bin/bash

docker kill training
docker rm training

tmux kill-session -t training
