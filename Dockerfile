FROM jenkins/jenkins:lts

USER root

# Install prerequisites
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    python3 \
    python3-pip \
    gnupg \
    software-properties-common \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# Install Terraform
RUN curl -fsSL https://releases.hashicorp.com/terraform/1.12.2/terraform_1.12.2_linux_amd64.zip -o terraform.zip \
    && unzip terraform.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform.zip

# Install Python virtual environment
RUN apt-get update && apt-get install -y python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Create and activate virtual environment for Ansible
RUN python3 -m venv /opt/ansible_venv
ENV PATH="/opt/ansible_venv/bin:$PATH"

# Install Ansible in the virtual environment
RUN /opt/ansible_venv/bin/pip install --no-cache-dir ansible

# Verify installations
RUN terraform --version && \
    ansible --version && \
    aws --version

# Switch back to Jenkins user
USER jenkins
