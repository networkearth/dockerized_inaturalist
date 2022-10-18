FROM ubuntu:20.04

# prevent input prompts
ENV DEBIAN_FRONTEND noninteractive

# install essentials
RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install build-essential && \
    apt-get -y install libcurl3-dev && \
    apt-get -y install libpq-dev && \
    apt-get -y install git && \
    apt-get -y install curl && \
    apt-get -y install unzip && \
    apt-get -y install libreadline-dev && \
    apt-get -y install libssl-dev && \
    apt-get -y install libtinfo-dev && \
    apt-get -y install zlib1g-dev

# some nice to haves
RUN apt-get -y install vim && \
    apt-get -y install tree

# base dependencies
RUN apt-get -y install imagemagick && \
    apt-get -y install exiftool && \
    apt-get -y install redis && \
    apt-get -y install memcached && \
    apt-get -y install libgeos-dev && \
    apt-get -y install libgeos++-dev && \
    apt-get -y install libproj-dev 

# postgres and postgis
RUN apt-get -y install postgresql-12 postgresql-client-12 postgis

# download and install nvm
RUN curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash 

# download and install rbenv
RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv && \
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc && \
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc

# install ruby build plugin
RUN git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

# setup locales
RUN locale-gen en_US en_US.UTF-8 && \
    dpkg-reconfigure locales

# install ruby 
RUN . /root/.bashrc && rbenv install 3.0.4

# install node
RUN . /root/.bashrc && nvm install 12.13.0

# grab the inaturalist code and cd into the directory
RUN git clone https://github.com/inaturalist/inaturalist.git
WORKDIR /inaturalist

RUN . /root/.bashrc && gem install bundler && bundler install
