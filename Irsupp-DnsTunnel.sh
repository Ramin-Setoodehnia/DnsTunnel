#!/bin/bash

echo "
  ___   ____    ____                              ____                  _____                                  _ 
 |_ _| |  _ \  / ___|   _   _   _ __    _ __     |  _ \   _ __    ___  |_   _|  _   _   _ __    _ __     ___  | |
  | |  | |_) | \___ \  | | | | | '_ \  | '_ \    | | | | | '_ \  / __|   | |   | | | | | '_ \  | '_ \   / _ \ | |
  | |  |  _ <   ___) | | |_| | | |_) | | |_) |   | |_| | | | | | \__ \   | |   | |_| | | | | | | | | | |  __/ | |
 |___| |_| \_\ |____/   \__,_| | .__/  | .__/    |____/  |_| |_| |___/   |_|    \__,_| |_| |_| |_| |_|  \___| |_|
                               |_|     |_|                                                                         
"

echo "--------------------------------------"
echo "💠 1. Install"
echo "🔄 2. Restart"
echo "⬆️ 3. Update"
echo "🛠️ 4. Edit"
echo "❌ 5. Close"
echo "--------------------------------------"
read -p "💬 Please choose an option (1/2/3/4/5): " OPTION

# انتخاب نقش و نام فایل سرویس
if [[ "$OPTION" == "1" || "$OPTION" == "2" || "$OPTION" == "3" || "$OPTION" == "4" ]]; then
    read -p "📍 Select Side (server/client): " ROLE
    SERVICE_FILE="/etc/systemd/system/iodine-${ROLE}.service"
fi

# پردازش انتخاب کاربر
case "$OPTION" in

    1)
        read -p "🌐 Enter Your NS Address (Example : dns.irsupp.ir): " DOMAIN
        read -p "🔑 Tunnel Password: " PASSWORD

        if [ "$ROLE" == "server" ]; then
            read -p "🎯 Enter Your Server Tunnel IP (Example: 10.0.0.1): " TUNNEL_IP
        elif [ "$ROLE" == "client" ]; then
            echo "✔️ On Client Side No Need IP. It's handled automatically."
        else
            echo "❌ Wrong Side"
            exit 1
        fi

        echo "🚀 Installing iodine..."
        apt update && apt install iodine -y

        echo "⚙️ Generating service file..."

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

        echo "🚦 Enabling and starting service..."
        systemctl daemon-reload
        systemctl enable $(basename "$SERVICE_FILE")
        systemctl restart $(basename "$SERVICE_FILE")

        echo "✅ $ROLE installed and running."
        systemctl status $(basename "$SERVICE_FILE") --no-pager
    ;;

    2)
        echo "🔄 Restarting service..."
        systemctl restart $(basename "$SERVICE_FILE")
        echo "✅ Service restarted."
        systemctl status $(basename "$SERVICE_FILE") --no-pager
    ;;

    3)
        echo "⬆️ Updating service..."
        nano "$SERVICE_FILE"
        systemctl daemon-reload
        systemctl restart $(basename "$SERVICE_FILE")
        echo "✅ Service updated and restarted."
    ;;

    4)
        echo "🛠️ Opening service file for manual edit..."
        nano "$SERVICE_FILE"
        systemctl daemon-reload
        systemctl restart $(basename "$SERVICE_FILE")
        echo "✅ Service edited and restarted."
    ;;

    5)
        echo "👋 Exiting script."
        exit 0
    ;;

    *)
        echo "❌ Invalid option selected."
    ;;

esac
