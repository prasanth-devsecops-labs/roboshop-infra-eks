#!/bin/bash
growpart /dev/nvme0n1 4
lvextend -L +5G /dev/mapper/RootVG-rootVol
lvextend -L +5G /dev/mapper/RootVG-homeVol
lvextend -L +10G /dev/mapper/RootVG-varVol

sudo dnf update -y

# Add Docker repo and install
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Required by SonarQube
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" >> /etc/sysctl.conf

sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Create sonar directory and compose file
mkdir -p /opt/sonar
cat <<'COMPOSE' > /opt/sonar/docker-compose.yml
version: "3"
services:
  sonarqube:
    image: sonarqube:community
    container_name: sonarqube
    depends_on:
      - db
    ports:
      - "9000:9000"
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonar
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: sonar
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_logs:/opt/sonarqube/logs
  db:
    image: postgres:15
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar
      POSTGRES_DB: sonar
    volumes:
      - postgresql:/var/lib/postgresql/data
volumes:
  sonarqube_data:
  sonarqube_logs:
  postgresql:
COMPOSE

# docker compose v2 plugin syntax (no hyphen)
cd /opt/sonar && sudo docker compose up -d
