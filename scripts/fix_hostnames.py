import socket

with open('/etc/slurm/slurm.conf') as f:
    d = f.read()

with open('/etc/slurm/slurm.conf', 'w') as f:
    f.write(d.replace('$HOSTNAME', socket.gethostname()))
