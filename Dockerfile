# Base image
FROM docker.io/library/archlinux:multilib-devel

# Install dependencies
RUN pacman -Syu --needed --noconfirm pacman-contrib git

# Setup user
RUN useradd -m builder && \
    mkdir -p /home/builder/bin && \
    echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
WORKDIR /home/builder
USER builder

# Copy files
COPY --chmod=755 scripts/*.sh /home/builder/bin/
COPY --chmod=755 entrypoint.sh /entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
