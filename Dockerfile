# Use jenkins base image
FROM jenkins/jenkins:latest
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
ENV CASC_JENKINS_CONFIG /var/jenkins_home/casc.yaml
# Run install as root
USER root

COPY plugins.txt plugins.txt
COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt
# RUN /usr/local/bin/install-plugins.sh < plugins.txt
COPY casc.yaml /var/jenkins_home/casc.yaml

RUN exit
# Install base tools
RUN apt-get update && apt-get install -y \
  apt-utils \
  wget \
  xz-utils \
  curl \
  git \
  openjdk-11-jdk \
  ant \
  nodejs \
  npm

	
ENV ANT_HOME /usr/share/java/apache-ant
ENV PATH $PATH:$ANT_HOME/bin
RUN exit

ENV DEBIAN_FRONTEND=noninteractive
ARG SALESFORCE_CLI_VERSION=latest-rc
ARG SF_CLI_VERSION=latest-rc

RUN echo 'a0f23911d5d9c371e95ad19e4e538d19bffc0965700f187840eb39a91b0c3fb0  ./nodejs.tar.gz' > node-file-lock.sha \
  && curl -s -o nodejs.tar.gz https://nodejs.org/dist/v16.13.2/node-v16.13.2-linux-x64.tar.gz \
  && shasum --check node-file-lock.sha
RUN mkdir /usr/local/lib/nodejs \
  && tar xf nodejs.tar.gz -C /usr/local/lib/nodejs/ --strip-components 1 \
  && rm nodejs.tar.gz node-file-lock.sha

ENV PATH=/usr/local/lib/nodejs/bin:$PATH
RUN npm install --global sfdx-cli@${SALESFORCE_CLI_VERSION} --ignore-scripts
RUN npm install --global @salesforce/cli@${SF_CLI_VERSION}

RUN apt-get update && apt-get install --assume-yes openjdk-11-jdk-headless jq
RUN apt-get autoremove --assume-yes \
  && apt-get clean --assume-yes \
  && rm -rf /var/lib/apt/lists/*

ENV SFDX_CONTAINER_MODE true
ENV DEBIAN_FRONTEND=dialog
ENV SHELL /bin/bash
RUN exit
RUN sfdx --version
RUN exit
RUN sfdx plugins:install @salesforce/sfdx-scanner
RUN exit
RUN echo y | sfdx plugins:install sfdx-git-delta
RUN exit
RUN sfdx plugins
RUN exit