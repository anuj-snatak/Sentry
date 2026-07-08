# Local-only Jenkins controller for testing the CloudForge pipeline end
# to end without a full EC2/Kubernetes Jenkins install. Bundles the same
# CLI tools jenkins/agent/Dockerfile provides for real agents, but on
# the controller itself (acting as its own "built-in node" executor) so
# a single container can run every pipeline stage. NOT the production
# artifact — see jenkins/agent/Dockerfile for that.

FROM jenkins/jenkins:lts-jdk17

USER root

ARG TERRAFORM_VERSION=1.7.5

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        unzip \
        git \
        jq \
        gnupg \
        lsb-release \
        ca-certificates \
        python3 \
        python3-pip \
        python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Terraform CLI
RUN curl -fsSL -o /tmp/terraform.zip \
        "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    && unzip -q /tmp/terraform.zip -d /usr/local/bin \
    && rm /tmp/terraform.zip \
    && terraform version

# AWS CLI v2
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/awscliv2.zip /tmp/aws \
    && aws --version

# SSM Session Manager plugin
RUN curl -fsSL "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" \
        -o /tmp/session-manager-plugin.deb \
    && dpkg -i /tmp/session-manager-plugin.deb \
    && rm /tmp/session-manager-plugin.deb

RUN pip3 install --no-cache-dir --break-system-packages \
        "ansible-core>=2.17,<2.18" \
        boto3 \
        botocore \
        PyYAML

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

COPY casc.yaml /var/jenkins_home/casc.yaml

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
ENV CASC_JENKINS_CONFIG="/var/jenkins_home/casc.yaml"

USER jenkins
