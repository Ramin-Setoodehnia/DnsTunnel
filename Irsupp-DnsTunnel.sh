#!/bin/bash

# رنگ‌ها
GREEN="\e[1;92m"
YELLOW="\e[1;93m"
ORANGE="\e[38;5;208m"
RED="\e[1;91m"
WHITE="\e[1;97m"
RESET="\e[0m"
CYAN="\e[1;96m"

# خطوط زرد
LINE="${YELLOW}═══════════════════════════════════════════${RESET}"

# گرفتن اطلاعات IP و موقعیت
IP_ADDR=$(curl -s ifconfig.me)
GEO_INFO=$(curl -s https://ipinfo.io/json)
LOCATION=$(echo "$GEO_INFO" | grep '"country"' | cut -d '"' -f4)
DATACENTER=$(echo "$GEO_INFO" | grep '"org"' | cut -d '"' -f4)

# بنر
echo -e "$LINE"
echo -e "${GREEN}Script Version${RESET}: ${YELLOW}v1${RESET}"
echo -e "${GREEN}Telegram Channel${RESET}: ${YELLOW}@irsuppchannel${RESET}"
echo -e "$LINE"
echo -e "${GREEN}IP Address${RESET}: ${YELLOW}$IP_ADDR${RESET}"
echo -e "${GREEN}Location${RESET}: ${YELLOW}$LOCATION${RESET}"
echo -e "${GREEN}Datacenter${RESET}: ${YELLOW}$DATACENTER${RESET}"
echo -e "$LINE"

# منوی رنگی
echo -e "${GREEN}1. Install${RESET}"
echo -e "${YELLOW}2. Restart${RESET}"
echo -e "${ORANGE}3. Update${RESET}"
echo -e "${WHITE}4. Edit${RESET}"
echo -e "${RED}5. Uninstall${RESET}"
echo    "6. Close"
echo -e "$LINE"
read -p "Select option (1/2/3/4/5/6): " OPTION

# تعیین نقش و فایل سرویس (برای همه گزینه‌ها به‌جز خروج)
if [[ "$OPTION" != "6" ]]; then
    read -p "Select Side (server/client): " ROLE
    SERVICE_FILE="/etc/systemd/system/iodine-${ROLE}.service"
fi

# عملیات
case "$OPTION" in

    1)
        read -p "NS Address: " DOMAIN
        read -p "Tunnel Password: " PASSWORD

        if [ "$ROLE" == "server" ]; then
            read -p "Server Tunnel IP: " TUNNEL_IP
        elif [ "$ROLE" == "client" ]; then
            echo -e "${GREEN}Client side detected. IP not required.${RESET}"
        else
            echo -e "${RED}Invalid side selected.${RESET}"
            exit 1
        fi

        echo -e "${GREEN}Installing iodine...${RESET}"
        apt update && apt install iodine -y

        echo -e "${GREEN}Building service...${RESET}"

        if [ "$ROLE" == "server" ]; then
            cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Iodine DNS Tunnel Server
After=network.target

[Service]
ExecStart=/usr/sbin/iodined -f -c -P $PASSWORD $TUNNEL_IP $DOMAIN
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF
        else
            cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Iodine DNS Tunnel Client
After=network.target
Wants=network-online.target

[Service]
ExecStart=/usr/sbin/iodine -f -P $PASSWORD $DOMAIN
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF
        fi

        echo -e "${GREEN}Enabling and starting service...${RESET}"
        systemctl daemon-reload
        systemctl enable $(basename "$SERVICE_FILE")
        systemctl restart $(basename "$SERVICE_FILE")

        echo -e "${GREEN}Installation complete.${RESET}"
        systemctl status $(basename "$SERVICE_FILE") --no-pager
    ;;

    2)
        echo -e "${YELLOW}Restarting service...${RESET}"
        systemctl restart $(basename "$SERVICE_FILE")
        echo -e "${GREEN}Service restarted.${RESET}"
        systemctl status $(basename "$SERVICE_FILE") --no-pager
    ;;

    3)
        echo -e "${ORANGE}Updating service (manual edit)...${RESET}"
        nano "$SERVICE_FILE"
        systemctl daemon-reload
        systemctl restart $(basename "$SERVICE_FILE")
        echo -e "${GREEN}Service updated and restarted.${RESET}"
    ;;

    4)
        echo -e "${WHITE}Opening service file for edit...${RESET}"
        nano "$SERVICE_FILE"
        systemctl daemon-reload
        systemctl restart $(basename "$SERVICE_FILE")
        echo -e "${GREEN}Service edited and restarted.${RESET}"
    ;;

    5)
        echo -e "${RED}Uninstalling service...${RESET}"
        systemctl stop $(basename "$SERVICE_FILE")
        systemctl disable $(basename "$SERVICE_FILE")
        rm -f "$SERVICE_FILE"
        systemctl daemon-reload
        echo -e "${GREEN}Service uninstalled.${RESET}"
    ;;

    6)
        echo "Closing script."
        exit 0
    ;;

    *)
        echo -e "${RED}Invalid option selected.${RESET}"
    ;;

esac
