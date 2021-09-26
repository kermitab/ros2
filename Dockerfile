FROM kermitab/ubuntu:focal_jp as foxy

ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Install ROS2
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg2 \
    lsb-release \
  && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null \
  && apt-get update && apt-get install -y --no-install-recommends \
    ros-foxy-ros-base \
    python3-argcomplete \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  # Create a non-root user
  && groupadd --gid $USER_GID $USERNAME \
  && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME

ENV ROS_DISTRO=foxy
ENV AMENT_PREFIX_PATH=/opt/ros/foxy
ENV COLCON_PREFIX_PATH=/opt/ros/foxy
ENV LD_LIBRARY_PATH=/opt/ros/foxy/lib
ENV PATH=/opt/ros/foxy/bin:$PATH
ENV PYTHONPATH=/opt/ros/foxy/lib/python3.8/site-packages
ENV ROS_PYTHON_VERSION=3
ENV ROS_VERSION=2
USER $USERNAME
WORKDIR /workspace

FROM foxy as foxy-dev

ENV DEBIAN_FRONTEND=noninteractive

ARG USERNAME=ros
USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
  bash-completion \
  build-essential \
  cmake \
  gdb \
  git \
  pylint3 \
  python3-argcomplete \
  python3-autopep8 \
  python3-colcon-common-extensions \
  python3-pip \
  python3-rosdep \
  python3-vcstool \
  ros-foxy-ament-lint \
  ros-foxy-launch-testing \
  ros-foxy-launch-testing-ament-cmake \
  ros-foxy-launch-testing-ros \
  sudo \
  vim \
  wget \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && rosdep init || echo "rosdep already initialized" \
  && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
  && chmod 0440 /etc/sudoers.d/$USERNAME \
  && echo "source /usr/share/bash-completion/completions/git" >> /home/$USERNAME/.bashrc \
  && echo "if [ -f /opt/ros/${ROS_DISTRO}/setup.bash ]; then source /opt/ros/${ROS_DISTRO}/setup.bash; fi" >> /home/$USERNAME/.bashrc

ENV DEBIAN_FRONTEND=
USER ros

FROM foxy-dev as foxy-redis-dev

ARG USERNAME=ros
USER root
WORKDIR /opt

RUN apt-get -y update && apt-get -y install --no-install-recommends \
  autoconf \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && git clone https://github.com/wingunder/redis-plus-plus-modules.git \
  && cd redis-plus-plus-modules \
  && ./bootstrap.sh \
  && ./configure \
  && make -j2

USER ros
WORKDIR /workspace
