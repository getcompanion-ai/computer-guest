FROM public.ecr.aws/docker/library/ubuntu:24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ARG MICROAGENT_TEST_AUTHORIZED_KEY=""

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    dbus-x11 \
    eza \
    fonts-dejavu-core \
    git \
    iproute2 \
    jitterentropy-rngd \
    net-tools \
    ncurses-bin \
    novnc \
    openbox \
    openssh-server \
    sudo \
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    websockify \
    x11-utils \
    x11-xserver-utils \
    x11vnc \
    xauth \
    xterm \
    xvfb \
  && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash node \
  && passwd -d node \
  && mkdir -p /home/node/.ssh \
  && chown -R node:node /home/node \
  && usermod -aG sudo node \
  && printf 'node ALL=(ALL) NOPASSWD:ALL\n' >/etc/sudoers.d/node \
  && chmod 440 /etc/sudoers.d/node \
  && install -d -m 0755 /etc/microagent

COPY docker/guest/sshd_config /etc/ssh/sshd_config
COPY docker/guest/microagent-init.sh /usr/local/bin/microagent-init
COPY docker/guest/microagent-desktop-session.sh /usr/local/bin/microagent-desktop-session
COPY docker/guest/microagent-network-up.sh /usr/local/bin/microagent-network-up
COPY docker/guest/defaults/.zshrc /home/node/.zshrc
COPY docker/guest/defaults/.bashrc /home/node/.bashrc
COPY docker/guest/defaults/.profile /home/node/.profile
COPY docker/guest/terminfo/xterm-ghostty.terminfo /tmp/xterm-ghostty.terminfo
COPY docker/guest/terminfo/xterm-kitty.terminfo /tmp/xterm-kitty.terminfo

RUN chmod 755 /usr/local/bin/microagent-init /usr/local/bin/microagent-desktop-session /usr/local/bin/microagent-network-up \
  && chown node:node /home/node/.zshrc /home/node/.bashrc /home/node/.profile \
  && usermod -s /usr/bin/zsh node \
  && install -d /opt/zsh/pure \
  && ln -sf /usr/local/bin/microagent-init /sbin/init \
  && curl -fsSL https://raw.githubusercontent.com/sindresorhus/pure/v1.27.0/pure.zsh -o /opt/zsh/pure/pure.zsh \
  && curl -fsSL https://raw.githubusercontent.com/sindresorhus/pure/v1.27.0/async.zsh -o /opt/zsh/pure/async.zsh \
  && tic -x -o /usr/share/terminfo /tmp/xterm-ghostty.terminfo \
  && tic -x -o /usr/share/terminfo /tmp/xterm-kitty.terminfo \
  && rm -f /tmp/xterm-ghostty.terminfo /tmp/xterm-kitty.terminfo

RUN if [ -n "$MICROAGENT_TEST_AUTHORIZED_KEY" ]; then \
      printf '%s\n' "$MICROAGENT_TEST_AUTHORIZED_KEY" >/etc/microagent/authorized_keys; \
      chmod 600 /etc/microagent/authorized_keys; \
    fi

CMD ["/usr/local/bin/microagent-init"]
