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

read -p "📍 Select Side (server/client): " ROLE
read -p "🌐 Enther Your NS Address (Example : dns.irsupp.ir): " DOMAIN
read -p "🔑 Tunnel Password: " PASSWORD

if [ "$ROLE" == "server" ]; then
    read -p "🎯 Enter Your Server Tunnel IP (Example: 10.0.0.1): " TUNNEL_IP
elif [ "$ROLE" == "client" ]; then
    echo "✔️ On Client Side No Need IP It choice Automaticaly"
else
    echo "❌ Wrong Side "
    exit 1
fi

# نصب iodine
echo "🚀 Install iodine..."
apt update && apt install iodine -y

# ساخت فایل سرویس systemd بر اساس نقش
SERVICE_FILE="/etc/systemd/system/iodine-${ROLE}.service"

echo "⚙️ Building a service based on the role..."

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

# فعال‌سازی و اجرای سرویس
echo "🚦 Activating and running the service..."
systemctl daemon-reload
systemctl enable $(basename "$SERVICE_FILE")
systemctl restart $(basename "$SERVICE_FILE")

echo "✅ $ROLE Side Installed and Ready"
echo "📊 Service status :"
systemctl status $(basename "$SERVICE_FILE") --no-pager

