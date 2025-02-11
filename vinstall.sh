#!/bin/bash

# Визначення кольорів
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'
RESET='\033[0m' # Скидання кольору

# Додавання ASCII-арту
clear
echo -e "${CYAN}"
echo "          __________  ____ ________  ___"
echo "         / ____/ __ \/  _//_  __/  |/  /"
echo "        / /   / /_/ // /   / / / /|_/ /"
echo "       / /___/ ____// / _ / / / /  / /"
echo "       \____/_/   /___/(_)_/ /_/  /_/"
echo -e "${RESET}"

echo -e "${WHITE}====================================================${RESET}"
echo -e "${CYAN}   Офіційний скрипт налаштування CPI.TM${RESET}"
echo -e "${WHITE}====================================================${RESET}\n"

# Оновлення системи
echo -e "${BLUE}Оновлення системи...${RESET}"
sudo apt-get update && sudo apt-get upgrade -y

# Встановлення необхідних пакетів
echo -e "${GREEN}Налаштування та встановлення потрібних компонентів...${RESET}"
sudo apt install -y curl ca-certificates locales

# Перевірка наявності Docker
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker не знайдений. Встановлюю Docker...${RESET}"
    # Встановлення Docker без запитів
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    docker --version
    echo -e "${GREEN}Docker успішно встановлено!${RESET}"
else
    echo -e "${GREEN}Docker вже встановлений.${RESET}"
fi

# Запит на встановлення Docker Compose
echo -e "${YELLOW}Встановити Docker Compose? (введіть yes або no): ${RESET}"
read install_compose
if [[ "$install_compose" == "yes" ]]; then
    echo -e "${WHITE}Встановлення Docker Compose...${RESET}"
    VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    docker-compose --version
    echo -e "${GREEN}Docker Compose успішно встановлено!${RESET}"
else
    echo -e "${YELLOW}Пропуск встановлення Docker Compose.${RESET}"
fi

# Запит облікових даних
echo -e "${CYAN}Введіть облікові дані для створення користувача${RESET}"
echo -e -n "${MAGENTA}Введіть ім'я користувача (CUSTOM_USER): ${RESET}"
read custom_user
echo -e -n "${MAGENTA}Введіть пароль (PASSWORD): ${RESET}"
read -s password
echo "" # Новий рядок для зручності

# Створення директорії Chromium
echo -e "${BLUE}Створення робочої директорії Chromium...${RESET}"
mkdir -p ~/chromium
cd ~/chromium || exit

# Створення файлу docker-compose.yml
echo -e "${BLUE}Створення docker-compose.yml...${RESET}"
cat <<EOF > docker-compose.yml
services:
  chromium:
    image: lscr.io/linuxserver/chromium:latest
    container_name: chromium_browser
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Kyiv
      - CUSTOM_USER=${custom_user}
      - PASSWORD=${password}
      - LANG=uk_UA.UTF-8
      - LANGUAGE=uk
      - LC_ALL=uk_UA.UTF-8
      - CHROME_CLI=https://www.google.com
      - VNC_LANGUAGE=uk
    ports:
      - "3050:3000"
      - "3051:3001"
    security_opt:
      - seccomp:unconfined
    volumes:
      - /root/chromium/config:/config
    shm_size: "1gb"
    restart: unless-stopped
EOF

# Запуск контейнера Chromium
echo -e "${WHITE}Запуск контейнера Chromium...${RESET}"
docker-compose up -d

# Завершення
echo -e "${GREEN}Встановлення завершено! Доступ до Chromium: http://<ip-адреса>:3050${RESET}"
