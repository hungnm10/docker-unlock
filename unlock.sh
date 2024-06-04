#!/bin/bash

# Check if Docker is installed
if command -v docker &>/dev/null; then
    echo "Docker is already installed."
else
    echo "Docker is not installed. Proceeding with installations..."
    # Install Docker-ce keyring
    sudo apt update -y
    sudo apt install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    FILE=/etc/apt/keyrings/docker.gpg
    if [ -f "$FILE" ]; then
        sudo rm "$FILE"
    fi
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o "$FILE"
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker-ce repository to Apt sources and install
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release; echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update -y
    sudo apt -y install docker-ce
fi

# Check if docker-compose is installed
if command -v docker-compose &>/dev/null; then
    echo "Docker-compose is already installed."
else
    echo "Docker-compose is not installed. Proceeding with installations..."

    # Install docker-compose subcommand
    sudo apt -y install docker-compose-plugin
    sudo ln -sv /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose
    docker-compose --version
fi

# New JSON content to add
new_mirrors=(
  "https://mirror.gcr.io"
)

if [ -f /etc/docker/daemon.json ]; then
  echo "File /etc/docker/daemon.json exists. Updating the content."
  current_mirrors=$(grep -oP '(?<="registry-mirrors": \[)[^]]*' /etc/docker/daemon.json | tr -d ' \n' | tr ',' '\n' | tr -d '"')
else
  echo "File /etc/docker/daemon.json does not exist. Creating a new file."
  current_mirrors=""
fi

combined_mirrors=$(echo -e "$current_mirrors\n${new_mirrors[*]}" | tr ' ' '\n' | sort | uniq)

new_content="{\n  \"registry-mirrors\": [\n"
for mirror in $combined_mirrors; do
  new_content+="    \"$mirror\",\n"
done

new_content=$(echo -e "$new_content" | sed '$ s/,$//')
new_content=$(echo -e "$new_content" | sed '$ s/,$//')
new_content="${new_content}\n  ]\n}"

echo -e "$new_content" | sudo tee /etc/docker/daemon.json > /dev/null

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NOCOLOR='\033[0m'

while true; do
    read -p "Restart Docker now? (y/N): "
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo systemctl restart docker
		echo
		echo -e "${GREEN}Docker restarted.${NOCOLOR}"
        break
    elif [[ $REPLY =~ ^[Nn]$ ]] || [[ -z $REPLY ]]; then
		echo
        echo -e "${YELLOW}Docker was not restarted. Please restart it manually to apply changes.${NOCOLOR}"
        break
	fi
done
