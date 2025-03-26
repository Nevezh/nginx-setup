#!/bin/bash

# Функция для запроса ввода
read -p "Введите домен (например, example.com): " DOMAIN

# Проверка, ввел ли пользователь домен
if [[ -z "$DOMAIN" ]]; then
    echo "Ошибка: Домен не может быть пустым!"
    exit 1
fi

# Установка зависимостей
echo "🔧 Устанавливаем Nginx и Certbot..."
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx

# Создание папки сайта
echo "📂 Создаем папку /var/www/$DOMAIN..."
sudo mkdir -p /var/www/$DOMAIN
echo "<h1>Сайт $DOMAIN работает!</h1>" | sudo tee /var/www/$DOMAIN/index.html

# Создание Nginx конфигурации
CONFIG_PATH="/etc/nginx/sites-available/$DOMAIN"

echo "📝 Создаем конфигурацию Nginx для $DOMAIN..."
sudo tee $CONFIG_PATH > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN www.$DOMAIN;

    root /var/www/$DOMAIN;
    index index.html index.php;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# Активируем конфигурацию
echo "🔗 Активируем сайт..."
sudo ln -s $CONFIG_PATH /etc/nginx/sites-enabled/

# Проверяем конфиг и перезапускаем Nginx
echo "🚀 Проверяем конфигурацию Nginx..."
sudo nginx -t && sudo systemctl restart nginx

# Получение SSL-сертификата
echo "🔐 Запрашиваем SSL-сертификат у Let's Encrypt..."
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN

# Проверяем автоматическое обновление сертификатов
echo "🔄 Проверяем обновление сертификатов..."
sudo certbot renew --dry-run

echo "✅ Домен $DOMAIN успешно настроен!"
