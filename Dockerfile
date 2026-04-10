FROM public.ecr.aws/docker/library/ubuntu:24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV EDITOR=nvim \
    VISUAL=nvim \
    XDG_CONFIG_HOME=/home/node/.config \
    XDG_CACHE_HOME=/home/node/.cache \
    XDG_DATA_HOME=/home/node/.local/share \
    XDG_STATE_HOME=/home/node/.local/state

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
  && mkdir -p /etc/apt/keyrings \
  && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
  && printf '%s\n' "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    bat \
    build-essential \
    dbus-x11 \
    dnsutils \
    eza \
    fd-find \
    file \
    fonts-dejavu-core \
    fzf \
    gh \
    git \
    iputils-ping \
    iproute2 \
    jitterentropy-rngd \
    jq \
    just \
    less \
    lsof \
    make \
    man-db \
    manpages \
    netcat-openbsd \
    net-tools \
    ncurses-bin \
    neovim \
    nodejs \
    novnc \
    openssh-server \
    pipx \
    procps \
    python3 \
    python3-pip \
    python3-venv \
    ripgrep \
    rsync \
    shellcheck \
    sqlite3 \
    sudo \
    tmux \
    tree \
    unzip \
    wget \
    xz-utils \
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    websockify \
    x11-utils \
    x11-xserver-utils \
    x11vnc \
    xauth \
    xvfb \
    xfce4-session \
    xfwm4 \
    xfdesktop4 \
    xfce4-settings \
    xfce4-terminal \
    xfconf \
    thunar \
    plank \
    e2fsprogs \
    autocutsel \
    greybird-gtk-theme \
    elementary-xfce-icon-theme \
    fonts-noto-core \
    fonts-noto-color-emoji \
    dbus-user-session \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/google-chrome-stable.deb \
      https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
  && apt-get update -qq \
  && apt-get install -y --no-install-recommends /tmp/google-chrome-stable.deb \
  && rm -f /tmp/google-chrome-stable.deb /etc/apt/sources.list.d/google-chrome.list \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/share/fonts/truetype/jetbrains-mono \
  && curl -fsSL -o /tmp/jbmono.tar.xz \
     https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.tar.xz \
  && tar xf /tmp/jbmono.tar.xz -C /usr/share/fonts/truetype/jetbrains-mono \
  && fc-cache -f \
  && rm -f /tmp/jbmono.tar.xz

RUN useradd --create-home --shell /bin/bash node \
  && passwd -d node \
  && mkdir -p /home/node/.ssh \
  && chown -R node:node /home/node \
  && usermod -aG sudo node \
  && printf 'node ALL=(ALL) NOPASSWD:ALL\n' >/etc/sudoers.d/node \
  && chmod 440 /etc/sudoers.d/node \
  && install -d -m 0755 /etc/microagent \
  && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
  && ln -sf /usr/bin/batcat /usr/local/bin/bat \
  && ln -sf /usr/bin/nvim /usr/local/bin/vim \
  && ln -sf /usr/bin/nvim /usr/local/bin/vi

COPY desktop/assets /opt/desktop/assets
COPY desktop/xfce /opt/desktop/xfce
COPY desktop/plank /opt/desktop/plank
COPY desktop/scripts /opt/desktop/scripts

COPY sshd_config /etc/ssh/sshd_config
COPY microagent-init.sh /usr/local/bin/microagent-init
COPY microagent-desktop-session.sh /usr/local/bin/microagent-desktop-session
COPY microagent-network-up.sh /usr/local/bin/microagent-network-up
COPY defaults/.zshrc /home/node/.zshrc
COPY defaults/.bashrc /home/node/.bashrc
COPY defaults/.profile /home/node/.profile
COPY terminfo/xterm-ghostty.terminfo /tmp/xterm-ghostty.terminfo
COPY terminfo/xterm-kitty.terminfo /tmp/xterm-kitty.terminfo

RUN chmod 755 /usr/local/bin/microagent-init /usr/local/bin/microagent-desktop-session /usr/local/bin/microagent-network-up \
  && chmod 755 /opt/desktop/scripts/apply-desktop-profile.sh \
  && chown node:node /home/node/.zshrc /home/node/.bashrc /home/node/.profile \
  && usermod -s /usr/bin/zsh node \
  && install -d /opt/zsh/pure \
  && ln -sf /usr/local/bin/microagent-init /sbin/init \
  && curl -fsSL https://raw.githubusercontent.com/sindresorhus/pure/v1.27.0/pure.zsh -o /opt/zsh/pure/pure.zsh \
  && curl -fsSL https://raw.githubusercontent.com/sindresorhus/pure/v1.27.0/async.zsh -o /opt/zsh/pure/async.zsh \
  && tic -x -o /usr/share/terminfo /tmp/xterm-ghostty.terminfo \
  && tic -x -o /usr/share/terminfo /tmp/xterm-kitty.terminfo \
  && rm -f /tmp/xterm-ghostty.terminfo /tmp/xterm-kitty.terminfo

RUN npm install -g \
      @anthropic-ai/claude-code \
      @openai/codex \
    && npm cache clean --force

CMD ["/usr/local/bin/microagent-init"]
