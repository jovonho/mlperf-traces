#!/bin/bash

mkdir output/
bpftrace -o ./output/bio.out ./trace_bio.bt &
echo $!
bpftrace -o ./output/vfs_rw.out ./trace_vfs_rw.bt &
echo $!
bpftrace -o ./output/open.out ./trace_open.bt &
echo $!

