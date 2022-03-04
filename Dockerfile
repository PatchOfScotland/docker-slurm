FROM ubuntu:18.04

ARG SLURM_DIR=/usr/local/src/slurm

# Get dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    libmunge-dev \
    locate \
    munge \
    nano \
    sudo \
    systemd \ 
    python3 

# setup required users
RUN groupadd -r --gid=990 slurm \
 && useradd -r -g slurm --uid=990 slurm
## May not be necessary for simple testing
#RUN groupadd -r --gid=993 munge
#RUN useradd -r -g munge uid=997 munge

# Setup install
RUN mkdir -p "$SLURM_DIR" 
COPY /slurm-21.08.5 "$SLURM_DIR"

# Setup required munge dirs
RUN mkdir -p /var/run/munge \
    && chown -R munge:munge /var/run/munge \
    && chown -R munge:munge /var/log/munge \
    && chown -R munge:munge /etc/munge \
    && chmod 770 /var/log/munge

# Setup required slurm dirs
RUN mkdir -p /var/spool/slurmd \
    && chown -R slurm:slurm /var/spool/slurmd \
    && chmod 775 /var/spool/slurmd
RUN mkdir -p /var/spool/slurmctld \
    && chown -R slurm:slurm /var/spool/slurmctld \
    && chmod 775 /var/spool/slurmctld

# Install slurm
RUN cd "$SLURM_DIR" \
    && ./configure --prefix=/usr --sysconfdir=/etc/slurm --libdir=/usr/lib \
    && make install \
    && ldconfig -n /usr/lib

COPY /slurm.conf /etc/slurm/
COPY /scripts /scripts
#RUN cd /scripts

RUN systemctl enable /usr/local/src/slurm/etc/slurmctld.service \
    && systemctl enable /usr/local/src/slurm/etc/slurmctld.service \
    && systemctl enable /usr/local/src/slurm/etc/slurmctld.service
