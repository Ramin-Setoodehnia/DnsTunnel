#!/bin/bash

echo "🛠️  IRsupp DNS Tunnel Auto Installer"
echo "--------------------------------------"

read -p "📍 لطفاً مشخص کن (server/client): " ROLE
read -p "🌐 دامنه (مثال: dns.irlesson.ir): " DOMAIN
read -p "🔑 پسورد تونل: " PASSWORD

if [ "$ROLE" == "server" ]; then
    read -p "🎯 آدرس IP داخل تونل (مثلاً 10.0.0.1): " TUNNEL_IP
elif [ "$ROLE" == "client" ]; then
    echo "✔️ حالت کلاینت انتخاب شد. IP داخل تونل نیاز نیست."
else
    echo "❌ نقش وارد شده نامعتبر است."
    exit 1
fi

# نصب iodine
echo "🚀 در حال نصب iodine..."
apt update && apt install iodine -y

# ساخت فایل سرویس systemd بر اساس نقش
SERVICE_FILE="/etc/systemd/system/iodine-${ROLE}.service"

echo "⚙️ در حال ساخت فایل سرویس systemd..."

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
echo "🚦 در حال فعال‌سازی و اجرای سرویس systemd..."
systemctl daemon-reload
systemctl enable $(basename "$SERVICE_FILE")
systemctl restart $(basename "$SERVICE_FILE")

echo "✅ نصب و راه‌اندازی $ROLE با موفقیت انجام شد!"
echo "📊 وضعیت سرویس:"
systemctl status $(basename "$SERVICE_FILE") --no-pager

