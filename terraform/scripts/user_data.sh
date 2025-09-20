#!/bin/bash
set -euxo pipefail

# Install necessary packages
sudo apt-get update
sudo apt-get install -y curl unzip jq

# Install Docker (for client nodes)
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker ubuntu # Assuming 'ubuntu' is the default user

# Install Nomad
NOMAD_VERSION="1.7.6" # Use a specific version
curl -L https://releases.hashicorp.com/nomad/$${NOMAD_VERSION}/nomad_$${NOMAD_VERSION}_linux_amd64.zip -o nomad.zip
unzip nomad.zip
sudo mv nomad /usr/local/bin/
rm nomad.zip

# Create Nomad configuration directory
sudo mkdir -p /etc/nomad.d
sudo chmod 700 /etc/nomad.d

# Determine if this is a server or client
if [ "${USER_DATA_INSTANCE_TYPE}" == "server" ]; then
  echo "Configuring Nomad as a server"
  sudo tee /etc/nomad.d/nomad.hcl > /dev/null <<EOF
data_dir = "/opt/nomad/data"
bind_addr = "0.0.0.0"

server {
  enabled          = true
  bootstrap_expect = 1 # For a single server, set to 1. For multiple, set to the number of servers.
}

ui {
  enabled = true
  listen_address = "0.0.0.0:4646"
}
EOF

  # Start Nomad server
  sudo tee /etc/systemd/system/nomad.service > /dev/null <<EOF
[Unit]
Description=Nomad Server
Documentation=https://www.nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/local/bin/nomad agent -config /etc/nomad.d
LimitNOFILE=65536
Restart=on-failure
RestartSec=2
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

else
  echo "Configuring Nomad as a client"
  sudo tee /etc/nomad.d/nomad.hcl > /dev/null <<EOF
data_dir = "/opt/nomad/data"
bind_addr = "0.0.0.0"

client {
  enabled = true
  servers = ["${NOMAD_SERVER_IP}:4647"] # This will be replaced by Terraform
  options = {
    "driver.docker.enabled" = true
  }
}
EOF

  # Start Nomad client
  sudo tee /etc/systemd/system/nomad.service > /dev/null <<EOF
[Unit]
Description=Nomad Client
Documentation=https://www.nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/local/bin/nomad agent -config /etc/nomad.d
LimitNOFILE=65536
Restart=on-failure
RestartSec=2
KillMode=process

[Install]
WantedBy=multi-user.target
EOF
fi

sudo systemctl enable nomad
sudo systemctl start nomad
