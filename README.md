# docker-slurm
slurm experiment container

# To run

docker build --tag dockerslurm .
docker run -it -d --mount type=bind,source="$(pwd)"/scripts,target=/scripts dockerslurm
docker exec -it XXXX bash

Once in the container:
service munge start
python3 fix_hostnames.py
slurmctld -D -vvvvv
slurmd -D -vvvvv

service munge start && python3 scripts/fix_hostnames.py && slurmctld && slurmd && cd /scripts

./test.sh 1
