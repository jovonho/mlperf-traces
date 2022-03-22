#!/bin/bash

if [ $# -eq 0 ]
then
    output_dir="./output"
else
    output_dir=$1
fi

if [ ! -d $output_dir ] 
then
    mkdir -p $output_dir
fi

sudo bpftrace -o "$output_dir/bio.out" ./trace_bio.bt &
echo $!
sudo bpftrace -o "$output_dir/vfs_rw.out" ./trace_vfs_rw.bt &
echo $!
sudo bpftrace -o "$output_dir/open.out" ./trace_open.bt &
echo $!
