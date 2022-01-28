#!/bin/bash

mkdir /data/MLIO/output/
sudo bpftrace -o /data/MLIO/output/bio.out ./trace_bio.bt &
echo $!
sudo bpftrace -o /data/MLIO/output/vfs_rw.out ./trace_vfs_rw.bt &
echo $!
sudo bpftrace -o /data/MLIO/output/open.out ./trace_open.bt &
echo $!

