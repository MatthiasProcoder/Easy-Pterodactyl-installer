#!/bin/bash

# ============================================
# Pterodactyl Installer
# Made by Matthias Coder
# Version: 3.2 - Complete Edition (STUCK FIXED)
# ============================================

# Color codes for beautiful output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
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
            printf "${YELLOW}%s [Y/n]: ${NC}" "$prompt"
        elif [ "$default" = "n" ]; then
            printf "${YELLOW}%s [y/N]: ${NC}" "$prompt"
        else
            printf "${YELLOW}%s [y/n]: ${NC}" "$prompt"
        fi
        
        read answer </dev/tty
        
        if [ "$default" = "y" ] && [ -z "$answer" ]; then
            answer="Y"
        elif [ "$default" = "n" ] && [ -z "$answer" ]; then
            answer="N"
        fi
        
        case $answer in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Function to get input - FIXED
get_input() {
    local prompt="$1"
    local default="$2"
    local input
    
    if [ -n "$default" ]; then
        printf "${YELLOW}%s [%s]: ${NC}" "$prompt" "$default"
    else
        printf "${YELLOW}%s: ${NC}" "$prompt"
    fi
    
    read input </dev/tty
    
    if [ -n "$input" ]; then
        echo "$input"
    else
        echo "$default"
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
    echo -e "${YELLOW}📋 Features: Panel | Wings | Blueprint | Nebula | Euphia Theme | Tools Suite${NC}"
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
    
    # Get configuration - using fixed get_input function
    FQDN=$(get_input "Enter your domain/subdomain" "panel.$(hostname -f)")
    EMAIL=$(get_input "Enter email for SSL certificate" "admin@${FQDN}")
    TIMEZONE=$(get_input "Enter your timezone" "UTC")
    
    # Generate secure passwords
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
    
    # Configure MySQL/MariaDB
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
    
    # Run migrations
    run_command "php artisan migrate --force" "Running database migrations"
    
    echo -e "${BLUE}Step 10: Seeding Database...${NC}"
    
    # Seed database
    run_command "php artisan db:seed --force" "Seeding database"
    
    echo -e "${BLUE}Step 11: Creating Admin User...${NC}"
    
    # Create admin user - FIXED with yes command
    echo "yes" | php artisan p:user:make --email="${EMAIL}" --username="admin" --name-first="Matthias" --name-last="Admin" --password="${ADMIN_PASSWORD}" --admin=1 >> $INSTALL_LOG 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Admin user created successfully${NC}"
    else
        echo -e "${YELLOW}⚠ Admin user creation failed. You can create manually later${NC}"
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

    ssl_certificate /etc/letsencrypt/live/${FQDN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${FQDN}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
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
    
    certbot certonly --standalone -d ${FQDN} --non-interactive --agree-tos --email ${EMAIL} --expand >> $INSTALL_LOG 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ SSL certificate obtained successfully${NC}"
    else
        echo -e "${YELLOW}⚠ SSL certificate failed. You can run manually later${NC}"
    fi
    
    run_command "systemctl start nginx" "Starting Nginx"
    
    echo -e "${BLUE}Step 16: Configuring Firewall...${NC}"
    
    # Configure firewall
    if command -v ufw &> /dev/null; then
        run_command "ufw allow 22/tcp" "Allowing SSH"
        run_command "ufw allow 80/tcp" "Allowing HTTP"
        run_command "ufw allow 443/tcp" "Allowing HTTPS"
        echo 'y' | ufw enable >> $INSTALL_LOG 2>&1
    fi
    
    echo -e "${BLUE}Step 17: Setting Up Cron Jobs...${NC}"
    
    # Setup cron job
    (crontab -l 2>/dev/null; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -
    
    # Create helper scripts
    cat > /root/backup_pterodactyl.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/root/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

echo "Starting Matthias Coder Backup..."
echo "======================================"

if [ -d "/var/www/pterodactyl" ]; then
    echo "Backing up panel files..."
    tar -czf $BACKUP_DIR/panel_files_$DATE.tar.gz /var/www/pterodactyl 2>/dev/null
    echo "✓ Panel files backed up"
fi

if command -v mysql &> /dev/null; then
    echo "Backing up database..."
    mysqldump panel > $BACKUP_DIR/database_$DATE.sql 2>/dev/null
    echo "✓ Database backed up"
fi

echo ""
echo "Backup completed: $BACKUP_DIR"
EOF
    
    chmod +x /root/backup_pterodactyl.sh
    
    # Final output
    clear
    show_banner
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           PANEL INSTALLATION COMPLETE!                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Panel URL: https://${FQDN}${NC}"
    echo -e "${CYAN}Admin Email: ${EMAIL}${NC}"
    echo -e "${CYAN}Admin Password: ${ADMIN_PASSWORD}${NC}"
    echo ""
    echo -e "${YELLOW}Credentials saved to: /root/matthias_panel_config.txt${NC}"
    echo -e "${YELLOW}Backup script: /root/backup_pterodactyl.sh${NC}"
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
        echo -e "${RED}Node secret is required!${NC}"
        echo -e "${YELLOW}Press Enter to return...${NC}"
        read
        return 1
    fi
    
    echo ""
    if ! ask_yes_no "Proceed with Wings installation?" "y"; then
        return 0
    fi
    
    echo -e "${BLUE}Step 1: Installing Docker...${NC}"
    curl -sSL https://get.docker.com/ | CHANNEL=stable bash >> $INSTALL_LOG 2>&1
    run_command "systemctl enable --now docker" "Starting Docker"
    
    echo -e "${BLUE}Step 2: Downloading Wings...${NC}"
    mkdir -p /etc/pterodactyl
    mkdir -p /var/lib/pterodactyl/volumes
    
    ARCH=$(uname -m)
    if [ "$ARCH" == "x86_64" ]; then
        WINGS_URL="https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64"
    else
        WINGS_URL="https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_arm64"
    fi
    
    run_command "curl -L -o /usr/local/bin/wings ${WINGS_URL}" "Downloading Wings"
    run_command "chmod u+x /usr/local/bin/wings" "Making Wings executable"
    
    echo -e "${BLUE}Step 3: Creating Wings User...${NC}"
    useradd -r -d /var/lib/pterodactyl -m -s /bin/bash wings 2>/dev/null || true
    usermod -aG docker wings
    
    echo -e "${BLUE}Step 4: Configuring Wings...${NC}"
    UUID=$(cat /proc/sys/kernel/random/uuid)
    
    cat > /etc/pterodactyl/config.yml << EOF
---
debug: false
uuid: ${UUID}
token_id: "${NODE_SECRET:0:20}"
token: "${NODE_SECRET}"
api:
  host: 0.0.0.0
  port: 8080
system:
  data: /var/lib/pterodactyl/volumes
  username: wings
sftp:
  bind_port: 2022
EOF
    
    echo -e "${BLUE}Step 5: Creating Systemd Service...${NC}"
    cat > /etc/systemd/system/wings.service << EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service

[Service]
User=wings
Group=wings
ExecStart=/usr/local/bin/wings
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    
    run_command "systemctl daemon-reload" "Reloading systemd"
    run_command "systemctl enable --now wings" "Starting Wings"
    
    echo -e "${GREEN}✓ Wings installation complete!${NC}"
    echo -e "${GREEN}Press Enter to return...${NC}"
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
        read
        return 1
    fi
    
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
    
    echo -e "${GREEN}✓ Blueprint installation complete!${NC}"
    echo -e "${GREEN}Press Enter to return...${NC}"
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
        read
        return 1
    fi
    
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
    php artisan migrate --force >> $INSTALL_LOG 2>&1
    
    echo -e "${GREEN}✓ Nebula installation complete!${NC}"
    echo -e "${GREEN}Press Enter to return...${NC}"
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
        read
        return 1
    fi
    
    if ! ask_yes_no "Install Euphia Theme?" "y"; then
        return 0
    fi
    
    cd /var/www/pterodactyl
    
    echo -e "${BLUE}Downloading Euphia Theme...${NC}"
    curl -L https://github.com/MatthiasProcoder/Euphia-Theme/archive/main.zip -o euphia.zip >> $INSTALL_LOG 2>&1
    unzip -o euphia.zip >> $INSTALL_LOG 2>&1
    cp -rf Euphia-Theme-main/* . >> $INSTALL_LOG 2>&1
    rm -rf Euphia-Theme-main euphia.zip
    
    php artisan view:clear
    php artisan cache:clear
    
    echo -e "${GREEN}✓ Euphia Theme installation complete!${NC}"
    echo -e "${GREEN}Press Enter to return...${NC}"
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
    echo "5) All Tools"
    echo "6) Return to Main Menu"
    echo ""
    
    read -p "Select option [1-6]: " tool_choice
    
    case $tool_choice in
        1) 
            echo -e "${GREEN}✓ Backup tools installed!${NC}"
            echo '#!/bin/bash
BACKUP_DIR="/root/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR
if [ -d "/var/www/pterodactyl" ]; then
    tar -czf $BACKUP_DIR/panel_backup_$DATE.tar.gz /var/www/pterodactyl 2>/dev/null
    echo "Backup completed: panel_backup_$DATE.tar.gz"
fi
if command -v mysql &> /dev/null; then
    mysqldump panel > $BACKUP_DIR/database_backup_$DATE.sql 2>/dev/null
    echo "Database backup completed"
fi' > /usr/local/bin/matthias-backup
            chmod +x /usr/local/bin/matthias-backup
            echo -e "${CYAN}Command: matthias-backup${NC}"
            ;;
        2)
            echo -e "${GREEN}✓ Monitoring tools installed!${NC}"
            echo '#!/bin/bash
echo "=== System Monitor ==="
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk "{print $2}")%"
echo "RAM: $(free -h | awk "/^Mem:/ {print \$3\"/\"\$2}")"
echo "Disk: $(df -h / | awk "NR==2 {print \$3\"/\"\$2}")"
systemctl is-active nginx && echo "✓ Nginx: Running" || echo "✗ Nginx: Stopped"
systemctl is-active wings && echo "✓ Wings: Running" || echo "✗ Wings: Stopped"' > /usr/local/bin/matthias-monitor
            chmod +x /usr/local/bin/matthias-monitor
            echo -e "${CYAN}Command: matthias-monitor${NC}"
            ;;
        3)
            echo -e "${GREEN}✓ Security tools installed!${NC}"
            apt install -y fail2ban >> $INSTALL_LOG 2>&1
            systemctl enable --now fail2ban
            echo -e "${CYAN}Fail2ban is now active${NC}"
            ;;
        4)
            echo -e "${GREEN}✓ Performance tools installed!${NC}"
            echo '#!/bin/bash
cd /var/www/pterodactyl 2>/dev/null && {
    php artisan optimize
    php artisan view:cache
    php artisan config:cache
    systemctl restart pteroq
    echo "Optimization complete!"
}' > /usr/local/bin/matthias-optimize
            chmod +x /usr/local/bin/matthias-optimize
            (crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/matthias-optimize > /dev/null 2>&1") | crontab -
            echo -e "${CYAN}Command: matthias-optimize (runs daily at 3 AM)${NC}"
            ;;
        5)
            echo -e "${GREEN}Installing all tools...${NC}"
            # Backup tools
            echo '#!/bin/bash
BACKUP_DIR="/root/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR
if [ -d "/var/www/pterodactyl" ]; then
    tar -czf $BACKUP_DIR/panel_backup_$DATE.tar.gz /var/www/pterodactyl 2>/dev/null
    echo "Backup completed: panel_backup_$DATE.tar.gz"
fi
if command -v mysql &> /dev/null; then
    mysqldump panel > $BACKUP_DIR/database_backup_$DATE.sql 2>/dev/null
    echo "Database backup completed"
fi' > /usr/local/bin/matthias-backup
            chmod +x /usr/local/bin/matthias-backup
            
            # Monitoring tools
            echo '#!/bin/bash
echo "=== System Monitor ==="
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk "{print $2}")%"
echo "RAM: $(free -h | awk "/^Mem:/ {print \$3\"/\"\$2}")"
echo "Disk: $(df -h / | awk "NR==2 {print \$3\"/\"\$2}")"
systemctl is-active nginx && echo "✓ Nginx: Running" || echo "✗ Nginx: Stopped"
systemctl is-active wings && echo "✓ Wings: Running" || echo "✗ Wings: Stopped"' > /usr/local/bin/matthias-monitor
            chmod +x /usr/local/bin/matthias-monitor
            
            # Security tools
            apt install -y fail2ban >> $INSTALL_LOG 2>&1
            systemctl enable --now fail2ban
            
            # Performance tools
            echo '#!/bin/bash
cd /var/www/pterodactyl 2>/dev/null && {
    php artisan optimize
    php artisan view:cache
    php artisan config:cache
    systemctl restart pteroq
    echo "Optimization complete!"
}' > /usr/local/bin/matthias-optimize
            chmod +x /usr/local/bin/matthias-optimize
            (crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/matthias-optimize > /dev/null 2>&1") | crontab -
            
            echo -e "${GREEN}✓ All tools installed!${NC}"
            echo -e "${CYAN}Commands: matthias-backup, matthias-monitor, matthias-optimize${NC}"
            ;;
        6) return 0 ;;
        *) echo -e "${RED}Invalid option${NC}" && sleep 2 && install_tools ;;
    esac
    
    echo ""
    echo -e "${GREEN}Press Enter to continue...${NC}"
    read
    install_tools
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
        1) 
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
            ;;
        2)
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
            ;;
        3)
            echo -e "${BLUE}Cleaning system...${NC}"
            apt autoremove -y
            apt autoclean
            journalctl --vacuum-time=7d
            rm -rf /tmp/*
            echo -e "${GREEN}✓ System cleaned!${NC}"
            ;;
        4) return 0 ;;
        *) echo -e "${RED}Invalid option${NC}" && sleep 2 && update_system ;;
    esac
    
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
    rm -f /usr/local/bin/matthias-*
    
    echo -e "${BLUE}Removing databases...${NC}"
    mysql -e "DROP DATABASE IF EXISTS panel;" 2>/dev/null
    mysql -e "DROP USER IF EXISTS 'pterodactyl'@'localhost';" 2>/dev/null
    
    echo -e "${BLUE}Removing systemd services...${NC}"
    rm -f /etc/systemd/system/pteroq.service
    rm -f /etc/systemd/system/wings.service
    systemctl daemon-reload
    
    if ask_yes_no "Remove Nginx configuration?" "n"; then
        rm -f /etc/nginx/sites-available/pterodactyl
        rm -f /etc/nginx/sites-enabled/pterodactyl
        systemctl restart nginx
    fi
    
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
