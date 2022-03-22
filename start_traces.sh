#!/bin/bash

# On DISCS, sudo commands don't have access to user directories
# Save the output somehwere we have acces
output="/data/MLIO/workloads/img_seg/output"

if [ $# -eq 0 ]
then
    #output_dir="./output"
	output_dir=$output
else
    output_dir=$1
fi

if [ ! -d $output_dir ] 
then
    mkdir -p $output_dir
fi

mpstat -P ALL -u 1 > $output_dir/cpu.out &
echo $!
#If training on GPU, uncomment this line
#nvidia-smi pmon 
sudo bpftrace -o "$output_dir/bio.out" ./trace_bio.bt &
echo $!
sudo bpftrace -o "$output_dir/vfs_rw.out" ./trace_vfs_rw.bt &
echo $!
sudo bpftrace -o "$output_dir/open.out" ./trace_open.bt &
echo $!

sleep 1
sudo ps aux | grep python > $output_dir/pids.out

