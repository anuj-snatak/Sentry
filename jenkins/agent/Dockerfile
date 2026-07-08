# CloudForge Jenkins agent: bundles every CLI tool the shared library's
# vars/ scripts shell out to (terraform, ansible-playbook, aws, the SSM
# Session Manager plugin) so pipeline runs don't depend on whatever
# happens to be installed on a given Jenkins node. Build once, push to
# your registry, and point the Jenkinsfile's `agent { docker { image } }`
# (or your Kubernetes/EC2 agent template) at it.
#
# Build:
#   docker build -t <your-registry>/cloudforge-jenkins-agent:latest jenkins/agent
# Push:
#   docker push <your-registry>/cloudforge-jenkins-agent:latest

FROM jenkins/inbound-agent:latest-jdk17

ARG TERRAFORM_VERSION=1.7.5
ARG TARGETARCH=amd64

USER root

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
        "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip" \
    && unzip -q /tmp/terraform.zip -d /usr/local/bin \
    && rm /tmp/terraform.zip \
    && terraform version

# AWS CLI v2
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/awscliv2.zip /tmp/aws \
    && aws --version

# SSM Session Manager plugin — required by Ansible's community.aws.aws_ssm
# connection plugin, which is how this platform reaches private-subnet
# instances without SSH or a bastion (see ansible/inventories/*/group_vars).
RUN curl -fsSL "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" \
        -o /tmp/session-manager-plugin.deb \
    && dpkg -i /tmp/session-manager-plugin.deb \
    && rm /tmp/session-manager-plugin.deb

# Ansible + the collections requirements.yml declares
RUN pip3 install --no-cache-dir --break-system-packages \
        "ansible-core>=2.17,<2.18" \
        boto3 \
        botocore

COPY ansible/requirements.yml /tmp/ansible-requirements.yml
RUN ansible-galaxy collection install -r /tmp/ansible-requirements.yml \
    && rm /tmp/ansible-requirements.yml

COPY python/requirements.txt /tmp/python-requirements.txt
RUN pip3 install --no-cache-dir --break-system-packages -r /tmp/python-requirements.txt \
    && rm /tmp/python-requirements.txt

USER jenkins
