
Edit the three directories in ./start_training.sh

You may need to modify the launch scripts and traces depending on the target machine.

There are some lines you need to uncomment to get the GPU monitoring.

Ex: you may not need to use sudo to run bpftrace, some bpf functionalities may not be available due to slightly different kernel versions (the most complicated as you would have to find a workaround in the traces).

If trying to run this on a new install, you'll have to install bcc and bpftrace, and possibly other tools like mpstat.
