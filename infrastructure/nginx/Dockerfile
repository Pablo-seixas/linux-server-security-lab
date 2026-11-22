FROM linux-server-security-lab-php:latest

USER root

RUN apt-get update \
    && apt-get install --yes --no-install-recommends nginx nftables openssh-server \
    && rm -f /etc/nginx/sites-enabled/default /etc/nginx/conf.d/default.conf \
    && useradd --create-home --shell /bin/bash labadmin \
    && passwd --delete labadmin \
    && install -d -m 0700 -o labadmin -g labadmin /home/labadmin/.ssh \
    && install -d -m 0755 /run/sshd \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint-security.sh /usr/local/bin/entrypoint-security
COPY sshd_config /etc/ssh/sshd_config
COPY --chown=labadmin:labadmin authorized_keys /home/labadmin/.ssh/authorized_keys
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint-security \
    && chmod 0755 /usr/local/bin/entrypoint-security \
    && chmod 0600 /home/labadmin/.ssh/authorized_keys \
    && ssh-keygen -A

ENTRYPOINT ["/usr/local/bin/entrypoint-security"]
