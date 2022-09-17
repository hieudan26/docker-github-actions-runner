# hadolint ignore=DL3007
FROM myoung34/github-runner-base:latest
LABEL maintainer="myoung34@my.apsu.edu"

ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
RUN mkdir -p /opt/hostedtoolcache

ARG GH_RUNNER_VERSION="2.296.2"
ARG TARGETPLATFORM

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /actions-runner
COPY install_actions.sh /actions-runner

RUN chmod +x /actions-runner/install_actions.sh \
  && /actions-runner/install_actions.sh ${GH_RUNNER_VERSION} ${TARGETPLATFORM} \
  && rm /actions-runner/install_actions.sh \
  && chown runner /_work /actions-runner /opt/hostedtoolcache

COPY token.sh entrypoint.sh /
RUN chmod +x /token.sh /entrypoint.sh

ARG ACCESS_TOKEN
ARG OWNER
ARG REPO
RUN mkdir opt

RUN apt-get update && apt-get install -y wget && \
    wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.4.1%2B1/OpenJDK17U-jdk_x64_linux_hotspot_17.0.4.1_1.tar.gz && \
    tar xvf OpenJDK17U-jdk_x64_linux_hotspot_17.0.4.1_1.tar.gz && \
    rm OpenJDK17U-jdk_x64_linux_hotspot_17.0.4.1_1.tar.gz &&\
    mv jdk-17.0.4.1+1/ /opt/jdk-17/
ENV JAVA_HOME /opt/jdk-17
ENV PATH $JAVA_HOME/bin:$PATH

RUN wget https://archive.apache.org/dist/maven/maven-3/3.8.1/binaries/apache-maven-3.8.1-bin.tar.gz && \
    tar -xvzf apache-maven-3.8.1-bin.tar.gz && \
    rm apache-maven-3.8.1-bin.tar.gz &&\
    mv apache-maven-3.8.1/ /opt/apache-maven-3.8.1/
ENV M2_HOME /opt/apache-maven-3.8.1
ENV PATH $M2_HOME/bin:$PATH

RUN source ~/.bashrc
RUN ls
RUN git clone https://${ACCESS_TOKEN}@github.com/${OWNER}/${REPO} work_dir
WORKDIR /actions-runner/work_dir
RUN ls
RUN mvn install

WORKDIR /actions-runner
RUN rm -rf work_dir

ENTRYPOINT ["/entrypoint.sh"]
CMD ["./bin/Runner.Listener", "run", "--startuptype", "service"]
