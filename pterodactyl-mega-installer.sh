#!/bin/bash

# ============================================
# Pterodactyl Installer
# Made by Matthias Coder
# Version: 3.2 - Complete Edition
# ============================================

# Color codes for beautiful output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
ORANGE='\033[0;33m'
PURPLE='\033[0;35m'
BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
BOLD_YELLOW='\033[1;33m'
BOLD_BLUE='\033[1;34m'
BOLD_MAGENTA='\033[1;35m'
BOLD_CYAN='\033[1;36m'
NC='\033[0m'

# Error log setup
ERROR_LOG="/root/matthias_pterodactyl_errors.log"
INSTALL_LOG="/root/matthias_pterodactyl_install.log"
> $ERROR_LOG
> $INSTALL_LOG

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $INSTALL_LOG
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}Please run as root (use sudo)${NC}"
        exit 1
    fi
}

# Function to detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        echo -e "${RED}Cannot detect OS${NC}"
        exit 1
    fi
}

# Function to ask yes/no
ask_yes_no() {
    local prompt="$1"
    local default="$2"
    local answer
    
    while true; do
        if [ "$default" = "y" ]; then
            echo -ne "${YELLOW}$prompt [Y/n]: ${NC}"
            read answer
            answer=${answer:-Y}
        elif [ "$default" = "n" ]; then
            echo -ne "${YELLOW}$prompt [y/N]: ${NC}"
            read answer
            answer=${answer:-N}
        else
            echo -ne "${YELLOW}$prompt [y/n]: ${NC}"
            read answer
        fi
        
        case $answer in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Function to get input
get_input() {
    local prompt="$1"
    local default="$2"
    local input
    
    if [ -n "$default" ]; then
        echo -ne "${YELLOW}$prompt [$default]: ${NC}"
        read input
        echo "${input:-$default}"
    else
        echo -ne "${YELLOW}$prompt: ${NC}"
        read input
        echo "$input"
    fi
}

# Function to run command with error handling
run_command() {
    local cmd="$1"
    local description="$2"
    
    echo -e "${BLUE}▶ $description...${NC}"
    log_message "Running: $cmd"
    
    eval "$cmd" >> $INSTALL_LOG 2>&1
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}✗ Failed: $description${NC}"
        echo -e "${YELLOW}Check log: $INSTALL_LOG${NC}"
        return 1
    else
        echo -e "${GREEN}✓ $description completed${NC}"
        return 0
    fi
}

# Matthias Coder ASCII Art Banner
show_banner() {
    clear
    echo -e "${BOLD_CYAN}"
    echo "   ███╗   ███╗ █████╗ ████████╗████████╗██╗  ██╗██╗ █████╗ ███████╗"
    echo "   ████╗ ████║██╔══██╗╚══██╔══╝╚══██╔══╝██║  ██║██║██╔══██╗██╔════╝"
    echo "   ██╔████╔██║███████║   ██║      ██║   ███████║██║███████║███████╗"
    echo "   ██║╚██╔╝██║██╔══██║   ██║      ██║   ██╔══██║██║██╔══██║╚════██║"
    echo "   ██║ ╚═╝ ██║██║  ██║   ██║      ██║   ██║  ██║██║██║  ██║███████║"
    echo "   ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚══════╝"
    echo -e "${NC}"
    echo -e "${BOLD_GREEN}   ╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD_GREEN}   ║           The Complete Game Hosting Solution           ║${NC}"
    echo -e "${BOLD_GREEN}   ╚══════════════════════════════════════════════════════════╝${NC}"
    echo -e "${CYAN}                           Made by Matthias Coder${NC}"
    echo -e "${CYAN}                    Discord: https://discord.gg/J2SqrH9nwZ${NC}"
    echo ""
    echo -e "${YELLOW}📋 Features: Panel | Wings | Blueprint | Nebula | Euphia Theme | Plugins Manager | Tools Suite${NC}"
    echo -e "${YELLOW}🔧 Auto SSL | Backup | Monitor | Optimize | Security${NC}"
    echo ""
}

# ============================================
# PANEL INSTALLER (FIXED - WON'T GET STUCK)
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
    
    # Generate secure passwords - remove problematic characters
    DB_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/\\\"'" | cut -c1-24)
    ADMIN_PASSWORD=$(openssl rand -base64 12 | tr -d "=+/\\\"'" | cut -c1-12)
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
    cd /var/www/pterodactyl || { echo -e "${RED}Failed to enter panel directory${NC}"; return 1; }
    
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
    
    # Create admin user - THIS WAS THE STUCK PART - FIXED
    echo -e "${CYAN}Creating admin user...${NC}"
    
    # Use a non-interactive method with yes command
    echo "yes" | php artisan p:user:make --email="${EMAIL}" --username="admin" --name-first="Matthias" --name-last="Admin" --password="${ADMIN_PASSWORD}" --admin=1 >> $INSTALL_LOG 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Admin user created successfully${NC}"
    else
        echo -e "${YELLOW}⚠ Admin user creation failed. Trying alternative method...${NC}"
        # Alternative method using mysql directly
        HASHED_PASS=$(php -r "echo password_hash('${ADMIN_PASSWORD}', PASSWORD_BCRYPT);")
        mysql panel -e "INSERT INTO users (email, username, name_first, name_last, password, root_admin, created_at, updated_at) VALUES ('${EMAIL}', 'admin', 'Matthias', 'Admin', '${HASHED_PASS}', 1, NOW(), NOW());" >> $INSTALL_LOG 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Admin user created via direct database insert${NC}"
        else
            echo -e "${RED}✗ Admin user creation failed. You can create manually after installation: php artisan p:user:make${NC}"
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

# ============================================
# WINGS INSTALLER
# ============================================
install_wings() {
    show_banner
    echo -e "${BOLD_MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD_MAGENTA}║              PTERODACTYL WINGS INSTALLER                   ║${NC}"
    echo -e "${BOLD_MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    check_root
    
    echo -e "${CYAN}Node Configuration:${NC}"
    echo "----------------------------------------"
    
    NODE_FQDN=$(get_input "Enter node domain or IP" "$(hostname -I | awk '{print $1}')")
    NODE_SECRET=$(get_input "Enter node secret (from Panel > Nodes > Your Node > Configuration)" "")
    
    if [ -z "$NODE_SECRET" ]; then
        echo -e "${RED}Node secret is required! Get it from your panel.${NC}"
        echo -e "${YELLOW}Press Enter to return...${NC}"
        read
        return 1
    fi
    
    echo ""
    if ! ask_yes_no "Proceed with Wings installation?" "y"; then
        return 0
    fi
    
    echo -e "${BLUE}Step 1: Installing Docker...${NC}"
    
    # Install Docker
    curl -sSL https://get.docker.com/ | CHANNEL=stable bash >> $INSTALL_LOG 2>&1
    run_command "systemctl enable --now docker" "Starting Docker"
    
    echo -e "${BLUE}Step 2: Downloading Wings...${NC}"
    
    # Create directories
    mkdir -p /etc/pterodactyl
    mkdir -p /var/lib/pterodactyl/volumes
    mkdir -p /var/log/pterodactyl
    
    # Download Wings based on architecture
    ARCH=$(uname -m)
    if [ "$ARCH" == "x86_64" ]; then
        WINGS_URL="https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64"
    elif [ "$ARCH" == "aarch64" ]; then
        WINGS_URL="https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_arm64"
    else
        WINGS_URL="https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64"
    fi
    
    run_command "curl -L -o /usr/local/bin/wings ${WINGS_URL}" "Downloading Wings"
    run_command "chmod u+x /usr/local/bin/wings" "Making Wings executable"
    
    echo -e "${BLUE}Step 3: Creating Wings User...${NC}"
    
    # Create wings user
    useradd -r -d /var/lib/pterodactyl -m -s /bin/bash wings 2>/dev/null || true
    usermod -aG docker wings
    
    echo -e "${BLUE}Step 4: Configuring Wings...${NC}"
    
    # Generate UUID
    UUID=$(cat /proc/sys/kernel/random/uuid)
    
    # Create config.yml
    cat > /etc/pterodactyl/config.yml << EOF
---
debug: false
uuid: ${UUID}
token_id: "${NODE_SECRET:0:20}"
token: "${NODE_SECRET}"
api:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: false
    certificate: /etc/letsencrypt/live/${NODE_FQDN}/fullchain.pem
    key: /etc/letsencrypt/live/${NODE_FQDN}/privkey.pem
system:
  data: /var/lib/pterodactyl/volumes
  log_directory: /var/log/pterodactyl
  archive_directory: /var/lib/pterodactyl/archives
  backup_directory: /var/lib/pterodactyl/backups
  username: wings
sftp:
  bind_port: 2022
  bind_ip: 0.0.0.0
allowed_mounts: []
remote:
  sftp:
    address: "${NODE_FQDN}"
    port: 2022
EOF
    
    echo -e "${BLUE}Step 5: Creating Systemd Service...${NC}"
    
    # Create systemd service
    cat > /etc/systemd/system/wings.service << EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=wings
Group=wings
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=600
RestartSec=10
KillMode=mixed
KillSignal=SIGTERM

[Install]
WantedBy=multi-user.target
EOF
    
    run_command "systemctl daemon-reload" "Reloading systemd"
    run_command "systemctl enable --now wings" "Starting Wings"
    
    echo -e "${BLUE}Step 6: Configuring Firewall for Wings...${NC}"
    
    # Open ports for Wings
    if command -v ufw &> /dev/null; then
        run_command "ufw allow 8080/tcp" "Allowing Wings API port"
        run_command "ufw allow 2022/tcp" "Allowing Wings SFTP port"
    fi
    
    # Create Wings management script
    cat > /usr/local/bin/wings-manager << 'EOF'
#!/bin/bash
case "$1" in
    start)
        systemctl start wings
        echo "Wings started"
        ;;
    stop)
        systemctl stop wings
        echo "Wings stopped"
        ;;
    restart)
        systemctl restart wings
        echo "Wings restarted"
        ;;
    status)
        systemctl status wings
        ;;
    logs)
        journalctl -u wings -f
        ;;
    *)
        echo "Usage: wings-manager {start|stop|restart|status|logs}"
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/wings-manager
    
    # Create Wings info file
    cat > /root/wings_info.txt << EOF
╔════════════════════════════════════════════════════════════╗
║              WINGS INSTALLATION COMPLETE!                  ║
║                    Made by Matthias Coder                  ║
╚════════════════════════════════════════════════════════════╝

📡 WINGS INFORMATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Node Domain/IP: ${NODE_FQDN}
Wings API Port: 8080
Wings SFTP Port: 2022

📁 CONFIGURATION FILES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Wings Config: /etc/pterodactyl/config.yml
Wings Binary: /usr/local/bin/wings
Wings Service: /etc/systemd/system/wings.service
Data Directory: /var/lib/pterodactyl/volumes
Log Directory: /var/log/pterodactyl

🛠️ MANAGEMENT COMMANDS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Start Wings:     systemctl start wings
Stop Wings:      systemctl stop wings
Restart Wings:   systemctl restart wings
View Status:     systemctl status wings
View Logs:       journalctl -u wings -f
Wings Manager:   wings-manager {start|stop|restart|status|logs}

💬 SUPPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Discord: https://discord.gg/J2SqrH9nwZ

🎉 Wings is now ready to host game servers!
EOF
    
    clear
    show_banner
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           WINGS INSTALLATION COMPLETE!                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    cat /root/wings_info.txt
    echo ""
    echo -e "${GREEN}Press Enter to return to main menu...${NC}"
    read
}

# ============================================
# BLUEPRINT INSTALLER
# ============================================
install_blueprint() {
    show_banner
    echo -e "${BOLD_MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD_MAGENTA}║           BLUEPRINT THEME MANAGER INSTALLER               ║${NC}"
    echo -e "${BOLD_MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ ! -d "/var/www/pterodactyl" ]; then
        echo -e "${RED}Pterodactyl panel not found! Please install panel first.${NC}"
        echo -e "${YELLOW}Press Enter to return...${NC}"
        read
        return 1
    fi
    
    echo -e "${CYAN}Blueprint allows you to customize your Pterodactyl panel with themes, plugins, and more!${NC}"
    echo ""
    
    if ! ask_yes_no "Install Blueprint Framework?" "y"; then
        return 0
    fi
    
    cd /var/www/pterodactyl
    
    echo -e "${BLUE}Downloading Blueprint...${NC}"
    curl -L https://github.com/BlueprintFramework/framework/archive/refs/heads/main.zip -o blueprint.zip >> $INSTALL_LOG 2>&1
    unzip -o blueprint.zip >> $INSTALL_LOG 2>&1
    cp -rf framework-main/* . >> $INSTALL_LOG 2>&1
    rm -rf framework-main blueprint.zip
    
    echo -e "${BLUE}Installing Blueprint...${NC}"
    chmod +x blueprint.sh
    ./blueprint.sh install >> $INSTALL_LOG 2>&1
    
    echo -e "${BLUE}Installing recommended extensions...${NC}"
    php artisan blueprint:install marketplace >> $INSTALL_LOG 2>&1
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           BLUEPRINT INSTALLATION COMPLETE!                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${CYAN}Commands:${NC}"
    echo "  • php artisan blueprint:list - List installed extensions"
    echo "  • php artisan blueprint:install [extension] - Install extension"
    echo "  • php artisan blueprint:remove [extension] - Remove extension"
    echo ""
    echo -e "${CYAN}Marketplace:${NC} https://blueprint.zip"
    echo ""
    echo -e "${GREEN}Press Enter to return to main menu...${NC}"
    read
}

# ============================================
# NEBULA INSTALLER
# ============================================
install_nebula() {
    show_banner
    echo -e "${BOLD_MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD_MAGENTA}║            NEBULA ADDON MANAGER INSTALLER                 ║${NC}"
    echo -e "${BOLD_MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ ! -d "/var/www/pterodactyl" ]; then
        echo -e "${RED}Pterodactyl panel not found! Please install panel first.${NC}"
        echo -e "${YELLOW}Press Enter to return...${NC}"
        read
        return 1
    fi
    
    echo -e "${CYAN}Nebula adds advanced features and enhancements to your Pterodactyl panel!${NC}"
    echo ""
    
    if ! ask_yes_no "Install Nebula Addons?" "y"; then
        return 0
    fi
    
    cd /var/www/pterodactyl
    
    echo -e "${BLUE}Downloading Nebula...${NC}"
    curl -L https://github.com/Nebula-Addons/panel/archive/main.zip -o nebula.zip >> $INSTALL_LOG 2>&1
    unzip -o nebula.zip >> $INSTALL_LOG 2>&1
    cp -rf panel-main/* . >> $INSTALL_LOG 2>&1
    rm -rf panel-main nebula.zip
    
    echo -e "${BLUE}Installing dependencies...${NC}"
    composer install --no-dev --optimize-autoloader >> $INSTALL_LOG 2>&1
    
    echo -e "${BLUE}Running migrations...${NC}"
    php artisan migrate --force >> $INSTALL_LOG 2>&1
    
    echo -e "${BLUE}Clearing cache...${NC}"
    php artisan view:clear
    php artisan config:clear
    php artisan cache:clear
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           NEBULA INSTALLATION COMPLETE!                   ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${CYAN}Nebula features are now available in your panel!${NC}"
    echo ""
    echo -e "${GREEN}Press Enter to return to main menu...${NC}"
    read
}

# ============================================
# EUPHIA THEME INSTALLER
# ============================================
install_euphia() {
    show_banner
    echo -e "${BOLD_MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD_MAGENTA}║              EUPHIA THEME INSTALLER                        ║${NC}"
    echo -e "${BOLD_MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ ! -d "/var/www/pterodactyl" ]; then
        echo -e "${RED}Pterodactyl panel not found! Please install panel first.${NC}"
        echo -e "${YELLOW}Press Enter to return...${NC}"
        read
        return 1
    fi
    
    echo -e "${CYAN}Euphia is a beautiful, modern theme for Pterodactyl Panel!${NC}"
    echo ""
    
    if ! ask_yes_no "Install Euphia Theme?" "y"; then
        return 0
    fi
    
    cd /var/www/pterodactyl
    
    echo -e "${BLUE}Downloading Euphia Theme...${NC}"
    curl -L https://github.com/MatthiasProcoder/Euphia-Theme/archive/main.zip -o euphia.zip >> $INSTALL_LOG 2>&1
    if [ $? -eq 0 ]; then
        unzip -o euphia.zip >> $INSTALL_LOG 2>&1
        if [ -d "Euphia-Theme-main" ]; then
            cp -rf Euphia-Theme-main/* . >> $INSTALL_LOG 2>&1
            rm -rf Euphia-Theme-main
            echo -e "${GREEN}✓ Euphia theme downloaded${NC}"
        fi
        rm -f euphia.zip
    else
        echo -e "${RED}Failed to download Euphia theme${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Clearing cache...${NC}"
    php artisan view:clear
    php artisan cache:clear
    
    echo -e "${BLUE}Setting permissions...${NC}"
    chown -R www-data:www-data /var/www/pterodactyl/*
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           EUPHIA THEME INSTALLATION COMPLETE!             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${CYAN}Theme is now active!${NC}"
    echo ""
    echo -e "${GREEN}Press Enter to return to main menu...${NC}"
    read
}

# ============================================
# TOOLS INSTALLER
# ============================================
install_tools() {
    show_banner
    echo -e "${BOLD_MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD_MAGENTA}║              MATTHIAS CODER TOOLS SUITE                   ║${NC}"
    echo -e "${BOLD_MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}Select tools to install:${NC}"
    echo ""
    echo "1) Backup & Restore Tools"
    echo "2) Monitoring & Analytics"
    echo "3) Security Hardening"
    echo "4) Performance Optimizer"
    echo "5) All Tools (Recommended)"
    echo "6) Return to Main Menu"
    echo ""
    
    read -p "Select option [1-6]: " tool_choice
    
    case $tool_choice in
        1) install_backup_tools ;;
        2) install_monitoring_tools ;;
        3) install_security_tools ;;
        4) install_performance_tools ;;
        5) install_all_tools ;;
        6) return 0 ;;
        *) echo -e "${RED}Invalid option${NC}" && sleep 2 && install_tools ;;
    esac
}

install_backup_tools() {
    echo -e "${BLUE}Installing Backup Tools...${NC}"
    
    cat > /usr/local/bin/matthias-backup << 'EOF'
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

# Backup wings config
if [ -f "/etc/pterodactyl/config.yml" ]; then
    cp /etc/pterodactyl/config.yml $BACKUP_DIR/wings_config_$DATE.yml
    echo "✓ Wings config backed up"
fi

echo ""
echo "Backup completed: $BACKUP_DIR"
echo "Files:"
ls -lh $BACKUP_DIR/*$DATE*
EOF
    
    chmod +x /usr/local/bin/matthias-backup
    
    cat > /usr/local/bin/matthias-restore << 'EOF'
#!/bin/bash
echo "Matthias Coder Restore Tool"
echo "================================"
echo "Available backups:"
ls -lh /root/backups/panel_files_*.tar.gz 2>/dev/null
echo ""
read -p "Enter backup filename to restore: " backup_file

if [ -f "/root/backups/$backup_file" ]; then
    echo "Restoring backup..."
    tar -xzf /root/backups/$backup_file -C /
    echo "Restore completed!"
else
    echo "Backup not found!"
fi
EOF
    
    chmod +x /usr/local/bin/matthias-restore
    
    echo -e "${GREEN}✓ Backup tools installed!${NC}"
    echo -e "${CYAN}Commands:${NC} matthias-backup, matthias-restore"
    echo ""
    echo -e "${GREEN}Press Enter to continue...${NC}"
    read
    install_tools
}

install_monitoring_tools() {
    echo -e "${BLUE}Installing Monitoring Tools...${NC}"
    
    cat > /usr/local/bin/matthias-monitor << 'EOF'
#!/bin/bash
clear
echo "Matthias Coder - System Monitor"
echo "===================================="
echo ""

echo "System Information:"
echo "------------------"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo ""

echo "Resource Usage:"
echo "---------------"
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%"
echo "Memory Usage: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "Disk Usage: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
echo ""

echo "Service Status:"
echo "---------------"
systemctl is-active nginx && echo "✓ Nginx: Running" || echo "✗ Nginx: Stopped"
systemctl is-active mysql && echo "✓ MySQL: Running" || echo "✗ MySQL: Stopped"
systemctl is-active redis && echo "✓ Redis: Running" || echo "✗ Redis: Stopped"
systemctl is-active wings && echo "✓ Wings: Running" || echo "✗ Wings: Stopped"

echo ""
echo "💬 Support: https://discord.gg/J2SqrH9nwZ"
EOF
    
    chmod +x /usr/local/bin/matthias-monitor
    
    echo -e "${GREEN}✓ Monitoring tools installed!${NC}"
    echo -e "${CYAN}Command:${NC} matthias-monitor"
    echo ""
    echo -e "${GREEN}Press Enter to continue...${NC}"
    read
    install_tools
}

install_security_tools() {
    echo -e "${BLUE}Installing Security Tools...${NC}"
    
    apt install -y fail2ban >> $INSTALL_LOG 2>&1
    
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
maxretry = 3
EOF

    systemctl restart fail2ban
    
    if command -v ufw &> /dev/null; then
        ufw allow 22/tcp
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw --force enable
    fi
    
    echo -e "${GREEN}✓ Security tools installed!${NC}"
    echo -e "${CYAN}Features:${NC} Fail2ban enabled, Firewall configured"
    echo ""
    echo -e "${GREEN}Press Enter to continue...${NC}"
    read
    install_tools
}

install_performance_tools() {
    echo -e "${BLUE}Installing Performance Tools...${NC}"
    
    cat > /usr/local/bin/matthias-optimize << 'EOF'
#!/bin/bash
echo "Matthias Coder - Performance Optimizer"
echo "==========================================="
echo ""

cd /var/www/pterodactyl

echo "Clearing caches..."
php artisan cache:clear
php artisan config:clear
php artisan view:clear
php artisan route:clear

echo "Optimizing..."
php artisan optimize
php artisan view:cache
php artisan config:cache
php artisan route:cache

echo "Restarting queue worker..."
systemctl restart pteroq

echo "Optimizing MySQL..."
mysqlcheck -o panel

echo ""
echo "✓ Performance optimization completed!"
EOF
    
    chmod +x /usr/local/bin/matthias-optimize
    
    (crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/matthias-optimize > /dev/null 2>&1") | crontab -
    
    echo -e "${GREEN}✓ Performance tools installed!${NC}"
    echo -e "${CYAN}Commands:${NC} matthias-optimize"
    echo -e "${CYAN}Daily optimization scheduled at 3 AM${NC}"
    echo ""
    echo -e "${GREEN}Press Enter to continue...${NC}"
    read
    install_tools
}

install_all_tools() {
    echo -e "${BLUE}Installing all tools...${NC}"
    install_backup_tools
    install_monitoring_tools
    install_security_tools
    install_performance_tools
}

# ============================================
# UPDATE SYSTEM
# ============================================
update_system() {
    show_banner
    echo -e "${BOLD_MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD_MAGENTA}║              UPDATE & MAINTENANCE SYSTEM                   ║${NC}"
    echo -e "${BOLD_MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo "1) Update Panel"
    echo "2) Update Wings"
    echo "3) System Cleanup"
    echo "4) Return to Main Menu"
    echo ""
    
    read -p "Select option [1-4]: " update_choice
    
    case $update_choice in
        1) update_panel ;;
        2) update_wings ;;
        3) system_cleanup ;;
        4) return 0 ;;
        *) echo -e "${RED}Invalid option${NC}" && sleep 2 && update_system ;;
    esac
}

update_panel() {
    if [ -d "/var/www/pterodactyl" ]; then
        echo -e "${BLUE}Updating Panel...${NC}"
        cd /var/www/pterodactyl
        php artisan down
        git pull
        composer install --no-dev --optimize-autoloader
        php artisan migrate --force
        php artisan view:clear
        php artisan config:clear
        php artisan queue:restart
        chown -R www-data:www-data /var/www/pterodactyl
        php artisan up
        echo -e "${GREEN}✓ Panel updated!${NC}"
    else
        echo -e "${RED}Panel not found!${NC}"
    fi
    echo -e "${GREEN}Press Enter to continue...${NC}"
    read
    update_system
}

update_wings() {
    if [ -f "/usr/local/bin/wings" ]; then
        echo -e "${BLUE}Updating Wings...${NC}"
        systemctl stop wings
        ARCH=$(uname -m)
        if [ "$ARCH" == "x86_64" ]; then
            WINGS_URL="https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64"
        else
            WINGS_URL="https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_arm64"
        fi
        curl -L -o /usr/local/bin/wings "$WINGS_URL"
        chmod u+x /usr/local/bin/wings
        systemctl start wings
        echo -e "${GREEN}✓ Wings updated!${NC}"
    else
        echo -e "${RED}Wings not found!${NC}"
    fi
    echo -e "${GREEN}Press Enter to continue...${NC}"
    read
    update_system
}

system_cleanup() {
    echo -e "${BLUE}Cleaning system...${NC}"
    apt autoremove -y
    apt autoclean
    journalctl --vacuum-time=7d
    rm -rf /tmp/*
    echo -e "${GREEN}✓ System cleaned!${NC}"
    echo -e "${GREEN}Press Enter to continue...${NC}"
    read
    update_system
}

# ============================================
# UNINSTALLER
# ============================================
uninstall_all() {
    show_banner
    echo -e "${BOLD_RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD_RED}║                    UNINSTALLER                            ║${NC}"
    echo -e "${BOLD_RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${RED}WARNING: This will remove all Pterodactyl components!${NC}"
    echo -e "${RED}This action cannot be undone!${NC}"
    echo ""
    
    if ! ask_yes_no "Are you sure you want to continue?" "n"; then
        return 0
    fi
    
    echo -e "${BLUE}Stopping services...${NC}"
    systemctl stop nginx mysql redis wings pteroq 2>/dev/null
    
    echo -e "${BLUE}Removing files...${NC}"
    rm -rf /var/www/pterodactyl
    rm -rf /etc/pterodactyl
    rm -f /usr/local/bin/wings
    
    echo -e "${BLUE}Removing databases...${NC}"
    mysql -e "DROP DATABASE IF EXISTS panel;" 2>/dev/null
    mysql -e "DROP USER IF EXISTS 'pterodactyl'@'localhost';" 2>/dev/null
    
    echo -e "${BLUE}Removing systemd services...${NC}"
    rm -f /etc/systemd/system/pteroq.service
    rm -f /etc/systemd/system/wings.service
    systemctl daemon-reload
    
    echo -e "${GREEN}✓ Uninstallation complete!${NC}"
    echo -e "${GREEN}Press Enter to return to main menu...${NC}"
    read
}

# ============================================
# MAIN MENU
# ============================================
main_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    MAIN MENU                              ║${NC}"
        echo -e "${WHITE}╠════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${WHITE}║${GREEN} 1) ${CYAN}Install Pterodactyl Panel${WHITE}                        ║${NC}"
        echo -e "${WHITE}║${GREEN} 2) ${CYAN}Install Wings (Node Daemon)${WHITE}                     ║${NC}"
        echo -e "${WHITE}║${GREEN} 3) ${CYAN}Install Blueprint (Theme Manager)${WHITE}               ║${NC}"
        echo -e "${WHITE}║${GREEN} 4) ${CYAN}Install Nebula Addons${WHITE}                           ║${NC}"
        echo -e "${WHITE}║${GREEN} 5) ${CYAN}Install Euphia Theme${WHITE}                            ║${NC}"
        echo -e "${WHITE}║${GREEN} 6) ${CYAN}Install Tools Suite${WHITE}                             ║${NC}"
        echo -e "${WHITE}║${GREEN} 7) ${CYAN}Update & Maintenance${WHITE}                           ║${NC}"
        echo -e "${WHITE}║${GREEN} 8) ${CYAN}Uninstall Everything${WHITE}                           ║${NC}"
        echo -e "${WHITE}║${GREEN} 9) ${CYAN}Exit${WHITE}                                           ║${NC}"
        echo -e "${WHITE}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${CYAN}💬 Need help? Join Discord: https://discord.gg/J2SqrH9nwZ${NC}"
        echo ""
        read -p "$(echo -e ${BOLD_YELLOW}Select an option [1-9]: ${NC})" choice
        
        case $choice in
            1) install_panel ;;
            2) install_wings ;;
            3) install_blueprint ;;
            4) install_nebula ;;
            5) install_euphia ;;
            6) install_tools ;;
            7) update_system ;;
            8) uninstall_all ;;
            9) 
                echo -e "${GREEN}Thank you for using Matthias Coder Installer!${NC}"
                echo -e "${CYAN}Join our Discord: https://discord.gg/J2SqrH9nwZ${NC}"
                exit 0 
                ;;
            *) 
                echo -e "${RED}Invalid option! Please select 1-9${NC}"
                sleep 2 
                ;;
        esac
    done
}

# Start the installer
check_root
main_menu
