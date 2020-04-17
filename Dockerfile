from ubuntu:18.04
ENV TZ=Asia/Shanghai
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
RUN apt-get update && apt-get install -y ca-certificates apt-utils gnupg gnupg1 gnupg2 \
&& (curl https://packages.gitlab.com/gpg.key 2> /dev/null | apt-key add - &>/dev/null) \
&& apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3F01618A51312F3F \
&& echo '\
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse\n\
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse\n\
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse\n\
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse\n\
deb https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/ubuntu bionic main\n' > /etc/apt/sources.list \
&& DEBIAN_FRONTEND=noninteractive apt-get update \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y gitlab-ce \ 
       libssl-dev \
       git \
       autoconf \
       zlib1g-dev \
       libpam0g-dev \
       libsystemd-dev \
       pkg-config \
       supervisor \
&& DEBIAN_FRONTEND=noninteractive apt-get autoclean -y && DEBIAN_FRONTEND=noninteractive apt-get autoremove -y
RUN (cd /root; git clone https://github.com/openssh/openssh-portable.git ; cd /root/openssh-portable && git checkout V_8_2)
RUN (cd /root/openssh-portable && autoreconf && ./configure  --with-md5-passwords --with-pam --with-zlib --with-systemd && make clean && make -j32 && make install)
RUN echo '\
[program:ssh]\n\
command=/usr/local/sbin/sshd -D\n\
autostart=true\n\
autorestart=true\n\
stopsignal=TERM\n' > /etc/supervisor/conf.d/ssh.conf

# Remove MOTD
RUN rm -rf /etc/update-motd.d /etc/motd /etc/motd.dynamic
RUN ln -fs /dev/null /run/motd.dynamic

# Copy assets
COPY assets/ /assets/
RUN /assets/setup

# Allow to access embedded tools
ENV PATH /opt/gitlab/embedded/bin:/opt/gitlab/bin:/assets:$PATH

# Resolve error: TERM environment variable not set.
ENV TERM xterm

# Expose web & ssh
EXPOSE 443 80 22

# Define data volumes
VOLUME ["/etc/gitlab", "/var/opt/gitlab", "/var/log/gitlab"]

# Wrapper to handle signal, trigger runit and reconfigure GitLab
CMD ["/assets/wrapper"]

HEALTHCHECK --interval=60s --timeout=30s --retries=5 \
CMD /opt/gitlab/bin/gitlab-healthcheck --fail --max-time 10

