# ============================================
# PANEL INSTALLER (FIXED VERSION)
# ============================================
install_panel() {
    show_banner
    echo -e "${BOLD_MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD_MAGENTA}║              PTERODACTYL PANEL INSTALLER                  ║${NC}"
    echo -e "${BOLD_MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    check_root
    detect_os
    
    echo -e "${CYAN}Step 1: Configuration${NC}"
    echo "----------------------------------------"
    
    # Get configuration
    FQDN=$(get_input "Enter your domain/subdomain" "panel.$(hostname -f)")
    EMAIL=$(get_input "Enter email for SSL certificate" "admin@${FQDN}")
    TIMEZONE=$(get_input "Enter your timezone" "UTC")
    
    # Generate secure passwords
    DB_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-24)
    ADMIN_PASSWORD=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-12)
    APP_KEY=$(openssl rand -base64 32)
    
    echo ""
    echo -e "${CYAN}Configuration Summary:${NC}"
    echo -e "  Domain: ${GREEN}${FQDN}${NC}"
    echo -e "  Email: ${GREEN}${EMAIL}${NC}"
    echo -e "  Timezone: ${GREEN}${TIMEZONE}${NC}"
    echo -e "  Database Password: ${GREEN}${DB_PASSWORD}${NC}"
    echo -e "  Admin Password: ${GREEN}${ADMIN_PASSWORD}${NC}"
    echo ""
    
    if ! ask_yes_no "Proceed with panel installation?" "y"; then
        return 0
    fi
    
    # Save configuration
    cat > /root/matthias_panel_config.txt << EOF
========================================
Matthias Coder - Panel Configuration
========================================
Installation Date: $(date)
Domain: ${FQDN}
SSL Email: ${EMAIL}
Timezone: ${TIMEZONE}
Database Name: panel
Database User: pterodactyl
Database Password: ${DB_PASSWORD}
Admin Email: ${EMAIL}
Admin Username: admin
Admin Password: ${ADMIN_PASSWORD}
App Key: ${APP_KEY}
========================================
EOF
    
    echo -e "${BLUE}Step 2: Installing Dependencies...${NC}"
    
    # Update system
    run_command "apt update" "Updating package lists"
    run_command "apt upgrade -y" "Upgrading packages"
    
    # Install base packages
    run_command "apt install -y curl wget git unzip tar nginx mysql-server redis-server mariadb-client mariadb-server software-properties-common ufw" "Installing base packages"
    
    # Add PHP repository and install PHP 8.1
    run_command "add-apt-repository -y ppa:ondrej/php" "Adding PHP repository"
    run_command "apt update" "Updating package lists"
    run_command "apt install -y php8.1 php8.1-cli php8.1-common php8.1-mysql php8.1-zip php8.1-gd php8.1-mbstring php8.1-curl php8.1-xml php8.1-bcmath php8.1-fpm php8.1-redis php8.1-intl php8.1-tokenizer" "Installing PHP 8.1 and extensions"
    
    # Set timezone
    run_command "timedatectl set-timezone ${TIMEZONE}" "Setting timezone"
    
    # Install Composer
    if ! command -v composer &> /dev/null; then
        run_command "curl -sS https://getcomposer.org/installer | php" "Downloading Composer"
        run_command "mv composer.phar /usr/local/bin/composer" "Moving Composer to PATH"
        run_command "chmod +x /usr/local/bin/composer" "Setting Composer permissions"
    fi
    
    # Install Certbot for SSL
    run_command "apt install -y certbot python3-certbot-nginx" "Installing Certbot"
    
    echo -e "${BLUE}Step 3: Starting Services...${NC}"
    
    # Start and enable services
    run_command "systemctl enable --now nginx" "Enabling Nginx"
    run_command "systemctl enable --now mysql" "Enabling MySQL"
    run_command "systemctl enable --now redis-server" "Enabling Redis"
    
    # Wait for MySQL to be ready
    echo -e "${BLUE}Waiting for MySQL to be ready...${NC}"
    sleep 10
    
    echo -e "${BLUE}Step 4: Configuring Database...${NC}"
    
    # Configure MySQL/MariaDB - Fix password escaping
    DB_PASSWORD_ESC=$(printf '%s\n' "$DB_PASSWORD" | sed -e 's/[\/&]/\\&/g')
    
    run_command "mysql -e \"CREATE DATABASE IF NOT EXISTS panel;\"" "Creating database"
    run_command "mysql -e \"CREATE USER IF NOT EXISTS 'pterodactyl'@'localhost' IDENTIFIED BY '${DB_PASSWORD_ESC}';\"" "Creating database user"
    run_command "mysql -e \"GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'localhost';\"" "Granting privileges"
    run_command "mysql -e \"FLUSH PRIVILEGES;\"" "Flushing privileges"
    
    echo -e "${BLUE}Step 5: Downloading Pterodactyl Panel...${NC}"
    
    # Clone panel
    run_command "rm -rf /var/www/pterodactyl" "Removing old installation"
    run_command "git clone https://github.com/pterodactyl/panel.git /var/www/pterodactyl" "Cloning Pterodactyl Panel"
    cd /var/www/pterodactyl
    
    echo -e "${BLUE}Step 6: Installing PHP Dependencies...${NC}"
    
    # Install dependencies
    run_command "composer install --no-dev --optimize-autoloader" "Installing PHP dependencies"
    
    echo -e "${BLUE}Step 7: Configuring Environment...${NC}"
    
    # Create environment file
    run_command "cp .env.example .env" "Creating environment file"
    run_command "sed -i \"s/APP_KEY=.*/APP_KEY=${APP_KEY}/\" .env" "Setting app key"
    run_command "sed -i \"s/APP_ENV=.*/APP_ENV=production/\" .env" "Setting environment"
    run_command "sed -i \"s/APP_DEBUG=.*/APP_DEBUG=false/\" .env" "Setting debug mode"
    run_command "sed -i \"s|APP_URL=.*|APP_URL=https://${FQDN}|\" .env" "Setting app URL"
    run_command "sed -i \"s/DB_DATABASE=.*/DB_DATABASE=panel/\" .env" "Setting database name"
    run_command "sed -i \"s/DB_USERNAME=.*/DB_USERNAME=pterodactyl/\" .env" "Setting database user"
    run_command "sed -i \"s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASSWORD_ESC}|\" .env" "Setting database password"
    
    echo -e "${BLUE}Step 8: Generating Application Key...${NC}"
    
    # Generate key
    run_command "php artisan key:generate --force" "Generating application key"
    
    echo -e "${BLUE}Step 9: Running Database Migrations...${NC}"
    
    # Run migrations (this might take a while)
    run_command "php artisan migrate --force" "Running database migrations"
    
    echo -e "${BLUE}Step 10: Seeding Database...${NC}"
    
    # Seed database
    run_command "php artisan db:seed --force" "Seeding database"
    
    echo -e "${BLUE}Step 11: Creating Admin User...${NC}"
    
    # Create admin user using artisan command instead of tinker (more reliable)
    php artisan p:user:make --email="${EMAIL}" --username="admin" --name-first="Matthias" --name-last="Admin" --password="${ADMIN_PASSWORD}" --admin=1 >> $INSTALL_LOG 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Admin user created successfully${NC}"
    else
        echo -e "${YELLOW}⚠ Admin user creation via artisan failed. Trying alternative method...${NC}"
        # Alternative method using mysql directly
        HASHED_PASS=$(php -r "echo password_hash('${ADMIN_PASSWORD}', PASSWORD_BCRYPT);")
        mysql panel -e "INSERT INTO users (email, username, name_first, name_last, password, root_admin, created_at, updated_at) VALUES ('${EMAIL}', 'admin', 'Matthias', 'Admin', '${HASHED_PASS}', 1, NOW(), NOW());" >> $INSTALL_LOG 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Admin user created via direct database insert${NC}"
        else
            echo -e "${RED}✗ Admin user creation failed. You can create manually: php artisan p:user:make${NC}"
        fi
    fi
    
    echo -e "${BLUE}Step 12: Setting Permissions...${NC}"
    
    # Set permissions
    run_command "chown -R www-data:www-data /var/www/pterodactyl" "Setting ownership"
    run_command "chmod -R 755 /var/www/pterodactyl/storage /var/www/pterodactyl/bootstrap/cache" "Setting permissions"
    
    echo -e "${BLUE}Step 13: Setting Up Queue Worker...${NC}"
    
    # Create queue worker service
    cat > /etc/systemd/system/pteroq.service << 'EOF'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    run_command "systemctl daemon-reload" "Reloading systemd"
    run_command "systemctl enable --now pteroq" "Starting queue worker"
    
    echo -e "${BLUE}Step 14: Configuring Nginx...${NC}"
    
    # Create Nginx configuration
    cat > /etc/nginx/sites-available/pterodactyl << EOF
# Pterodactyl Panel Nginx Configuration
# Made by Matthias Coder

server {
    listen 80;
    server_name ${FQDN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${FQDN};

    root /var/www/pterodactyl/public;
    index index.php;

    access_log /var/log/nginx/pterodactyl.app-access.log;
    error_log /var/log/nginx/pterodactyl.app-error.log error;

    # SSL Configuration (will be added by Certbot)
    ssl_certificate /etc/letsencrypt/live/${FQDN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${FQDN}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;
    
    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
    
    location ~ /\.env {
        deny all;
    }
    
    location ~ /\.git {
        deny all;
    }
    
    location ~ /storage/.*\.(php|phtml|html|htm)$ {
        deny all;
    }
}
EOF
    
    # Enable site
    run_command "ln -sf /etc/nginx/sites-available/pterodactyl /etc/nginx/sites-enabled/" "Enabling Nginx site"
    run_command "rm -f /etc/nginx/sites-enabled/default" "Removing default site"
    run_command "nginx -t" "Testing Nginx configuration"
    run_command "systemctl restart nginx" "Restarting Nginx"
    
    echo -e "${BLUE}Step 15: Obtaining SSL Certificate...${NC}"
    
    # Get SSL certificate
    run_command "systemctl stop nginx" "Stopping Nginx for SSL"
    
    if certbot certonly --standalone -d ${FQDN} --non-interactive --agree-tos --email ${EMAIL} --expand >> $INSTALL_LOG 2>&1; then
        echo -e "${GREEN}✓ SSL certificate obtained successfully${NC}"
    else
        echo -e "${YELLOW}⚠ SSL certificate failed. Trying webroot method...${NC}"
        run_command "systemctl start nginx" "Starting Nginx"
        certbot certonly --webroot -w /var/www/pterodactyl/public -d ${FQDN} --non-interactive --agree-tos --email ${EMAIL} >> $INSTALL_LOG 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ SSL certificate obtained with webroot method${NC}"
        else
            echo -e "${RED}✗ SSL certificate failed. You can run manually: certbot --nginx -d ${FQDN}${NC}"
        fi
    fi
    
    run_command "systemctl start nginx" "Starting Nginx"
    
    echo -e "${BLUE}Step 16: Configuring Firewall...${NC}"
    
    # Configure firewall
    if command -v ufw &> /dev/null; then
        run_command "ufw allow 22/tcp" "Allowing SSH"
        run_command "ufw allow 80/tcp" "Allowing HTTP"
        run_command "ufw allow 443/tcp" "Allowing HTTPS"
        echo -e "${YELLOW}Note: Firewall will be enabled after installation completes${NC}"
    fi
    
    echo -e "${BLUE}Step 17: Setting Up Cron Jobs...${NC}"
    
    # Setup cron job for schedule:run
    (crontab -l 2>/dev/null; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -
    
    # Create backup script
    cat > /root/backup_pterodactyl.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/root/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

echo "Starting Matthias Coder Backup..."
echo "======================================"

# Backup panel files
if [ -d "/var/www/pterodactyl" ]; then
    echo "Backing up panel files..."
    tar -czf $BACKUP_DIR/panel_files_$DATE.tar.gz /var/www/pterodactyl 2>/dev/null
    echo "✓ Panel files backed up"
fi

# Backup database
if command -v mysql &> /dev/null; then
    echo "Backing up database..."
    mysqldump panel > $BACKUP_DIR/database_$DATE.sql 2>/dev/null
    echo "✓ Database backed up"
fi

# Backup nginx config
if [ -f "/etc/nginx/sites-available/pterodactyl" ]; then
    cp /etc/nginx/sites-available/pterodactyl $BACKUP_DIR/nginx_config_$DATE.conf
    echo "✓ Nginx config backed up"
fi

# Backup .env file
if [ -f "/var/www/pterodactyl/.env" ]; then
    cp /var/www/pterodactyl/.env $BACKUP_DIR/env_backup_$DATE.txt
    echo "✓ Environment file backed up"
fi

echo ""
echo "Backup completed: $BACKUP_DIR"
echo "Files:"
ls -lh $BACKUP_DIR/*$DATE*
EOF
    
    chmod +x /root/backup_pterodactyl.sh
    
    # Create update script
    cat > /root/update_pterodactyl.sh << 'EOF'
#!/bin/bash
echo "Matthias Coder - Update Script"
echo "==================================="
echo ""

cd /var/www/pterodactyl

echo "Putting panel in maintenance mode..."
php artisan down

echo "Pulling latest changes..."
git pull

echo "Installing dependencies..."
composer install --no-dev --optimize-autoloader

echo "Running migrations..."
php artisan migrate --force

echo "Clearing cache..."
php artisan view:clear
php artisan config:clear
php artisan cache:clear

echo "Restarting queue worker..."
php artisan queue:restart

echo "Setting permissions..."
chown -R www-data:www-data /var/www/pterodactyl

echo "Bringing panel back online..."
php artisan up

echo ""
echo "✓ Update completed successfully!"
EOF
    
    chmod +x /root/update_pterodactyl.sh
    
    # Create health check script
    cat > /root/health_check.sh << 'EOF'
#!/bin/bash
clear
echo "Matthias Coder - Health Check"
echo "=================================="
echo ""

echo "1. System Information:"
echo "   Hostname: $(hostname)"
echo "   Uptime: $(uptime -p)"
echo "   Load: $(uptime | awk -F'load average:' '{print $2}')"
echo ""

echo "2. Resource Usage:"
echo "   CPU: $(top -bn1 | grep 'Cpu(s)' | awk '{print $2}')%"
echo "   RAM: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "   Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
echo ""

echo "3. Service Status:"
services=("nginx" "mysql" "redis-server" "pteroq" "php8.1-fpm")
for service in "${services[@]}"; do
    if systemctl is-active --quiet $service; then
        echo "   ✓ $service: Running"
    else
        echo "   ✗ $service: Stopped"
    fi
done

echo ""
echo "4. Panel Accessibility:"
if curl -s -o /dev/null -w "%{http_code}" https://localhost 2>/dev/null | grep -q "200\|301\|302"; then
    echo "   ✓ Panel is accessible"
else
    echo "   ✗ Panel is not accessible"
fi

echo ""
echo "5. Database Connection:"
if mysql -e "USE panel" 2>/dev/null; then
    echo "   ✓ Database connection successful"
else
    echo "   ✗ Database connection failed"
fi

echo ""
echo "=================================="
echo "Health Check Complete!"
EOF
    
    chmod +x /root/health_check.sh
    
    # Enable firewall last
    if command -v ufw &> /dev/null; then
        echo -e "${BLUE}Enabling firewall...${NC}"
        echo 'y' | ufw enable >> $INSTALL_LOG 2>&1
    fi
    
    # Create final info file
    cat > /root/pterodactyl_info.txt << EOF
╔════════════════════════════════════════════════════════════╗
║          PTERODACTYL PANEL INSTALLATION COMPLETE!          ║
║                    Made by Matthias Coder                  ║
╚════════════════════════════════════════════════════════════╝

📊 PANEL INFORMATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
URL: https://${FQDN}
Admin Email: ${EMAIL}
Admin Password: ${ADMIN_PASSWORD}

🗄️ DATABASE INFORMATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Database Name: panel
Database User: pterodactyl
Database Password: ${DB_PASSWORD}

📁 CONFIGURATION FILES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Panel Config: /var/www/pterodactyl/.env
Nginx Config: /etc/nginx/sites-available/pterodactyl
Queue Worker: /etc/systemd/system/pteroq.service

🛠️ HELPER SCRIPTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Backup:    /root/backup_pterodactyl.sh
Update:    /root/update_pterodactyl.sh
Health:    /root/health_check.sh

📋 USEFUL COMMANDS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Restart Panel:   systemctl restart nginx php8.1-fpm pteroq
View Logs:       tail -f /var/www/pterodactyl/storage/logs/laravel.log
Create Backup:   /root/backup_pterodactyl.sh
Update Panel:    /root/update_pterodactyl.sh
Health Check:    /root/health_check.sh

💬 SUPPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Discord: https://discord.gg/J2SqrH9nwZ

⚠️  IMPORTANT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Save these credentials securely!
Change your admin password after first login!

🎉 Thank you for using Matthias Coder Installer!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    
    # Final output
    clear
    show_banner
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           PANEL INSTALLATION COMPLETE!                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    cat /root/pterodactyl_info.txt
    echo ""
    echo -e "${YELLOW}All credentials saved to: /root/pterodactyl_info.txt${NC}"
    echo -e "${YELLOW}Installation log: $INSTALL_LOG${NC}"
    echo ""
    echo -e "${GREEN}Press Enter to return to main menu...${NC}"
    read
}
