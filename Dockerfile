#FROM debian:stretch
FROM debian:jessie-backports

ENV container docker

# Add services helper utilities to start and stop LAVA
COPY scripts/*.sh /

# Install debian packages used by the container
# Configure apache to run the lava server
# Log the hostname used during install for the slave name
# Don't start any optional services except for the few we need.
RUN find /etc/systemd/system \
         /lib/systemd/system \
         -path '*.wants/*' \
         -not -name '*journald*' \
         -not -name '*systemd-tmpfiles*' \
         -not -name '*systemd-user-sessions*' \
         -not -name 'runlevel3.target' \
         -exec rm \{} \; \
 && systemctl set-default multi-user.target \
 && ln -s ../runlevel3.target /lib/systemd/system/multi-user.target.wants \
 && echo 'lava-server   lava-server/instance-name string lava-docker-instance' | debconf-set-selections \
 && echo 'locales locales/locales_to_be_generated multiselect C.UTF-8 UTF-8, en_US.UTF-8 UTF-8 ' | debconf-set-selections \
 && echo 'locales locales/default_environment_locale select en_US.UTF-8' | debconf-set-selections \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
 # install these older version packages to descrease the image size
 #lava-coordinator \
 #lava-dispatcher \
 #linaro-image-tools \
 postgresql \
 screen \
 sudo \
 wget \
 gnupg \
 vim-tiny \
 tftpd-hpa \
 && service postgresql start \
 && wget http://images.validation.linaro.org/production-repo/production-repo.key.asc \
 && apt-key add production-repo.key.asc \
 && echo 'deb http://images.validation.linaro.org/production-repo/ jessie-backports main' > /etc/apt/sources.list.d/lava.list \
 && apt-get clean && apt-get update \
 # removed --no-install-recommends option for now, will add it back later
 && DEBIAN_FRONTEND=noninteractive apt-get -t jessie-backports install -y \
 lava-server \
 lava-tool \
 ser2net \
 u-boot-tools \
 python-setproctitle \
 && apt-get clean \
 # remove some unused packages to decrease the image size
 #&& apt-get purge python3.4 qemu-system-arm -y \
 && a2dissite 000-default \
 && a2enmod proxy \
 && a2enmod proxy_http \
 && a2ensite lava-server.conf \
 && apt-get autoremove -y \
 && mv /usr/share/doc/lava* /root && rm -rf /usr/share/doc/* && mv /root/lava* /usr/share/doc/ \
 && service postgresql stop

COPY configs/tftpd-hpa /etc/default/tftpd-hpa

EXPOSE 69/udp 80 3079 5555 5556

#CMD /start.sh && bash

STOPSIGNAL SIGRTMIN+3

# Create a admin user (Insecure note, this creates a default user, username: admin/admin)
#RUN /start.sh \
# && lava-server manage users add --passwd admin --staff --superuser --email admin@example.com admin \
# && dpkg -l lava-server lava-dispatcher lava-tool python-django python-django-tables2 \
# && /stop.sh

# use volume mounts to handle persistence and to avoid writes to union filesystem
VOLUME "/var/lib/postgresql"

# Workaround for docker/docker#27202, technique based on comments from docker/docker#9212
CMD ["/bin/bash", "-c", "exec /sbin/init --log-target=journal 3>&1"]
