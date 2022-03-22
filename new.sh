#!/bin/bash

/usr/share/bcc/tools/cachestat -T 1 > $1/trace_cache &
echo $!

