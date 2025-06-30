#!/bin/bash

# Minecraft Everywhere - One-liner Deployment Script
# Repository: https://github.com/zardoy/minecraft-everywhere

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/zardoy/minecraft-web-client"
API_URL="https://api.github.com/repos/zardoy/minecraft-web-client"
INSTALL_DIR="/opt/minecraft-web-client"
STATIC_DIR="/var/www/html/minecraft"
SERVICE_NAME="mwc-server"

# Utility functions
print_header() {
    echo -e "${PURPLE}"
    echo "███╗   ███╗ ██████╗██████╗  █████╗ ███████╗████████╗"
    echo "████╗ ████║██╔════╝██╔══██╗██╔══██╗██╔════╝╚══██╔══╝"
    echo "██╔████╔██║██║     ██████╔╝███████║█████╗     ██║   "
    echo "██║╚██╔╝██║██║     ██╔══██╗██╔══██║██╔══╝     ██║   "
    echo "██║ ╚═╝ ██║╚██████╗██║  ██║██║  ██║██║        ██║   "
    echo "╚═╝     ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝        ╚═╝   "
    echo -e "${NC}"
    echo -e "${CYAN}🎮 MCRAFT.FUN Project: Minecraft Everywhere - Self-hosted Web Client Deployment${NC}"
    echo -e "${WHITE}Repository: https://github.com/zardoy/minecraft-everywhere${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root. This is not recommended for security reasons."
        while true; do
            read -p "Continue anyway? [y/N] " yn
            case $yn in
                [Yy]* ) break;;
                [Nn]* | "" ) exit 1;;
                * ) echo "Please answer y or n.";;
            esac
        done
    fi
}

# Check if running interactively
check_interactive() {
    if [[ ! -t 0 ]]; then
        print_error "This script must be run interactively."
        print_info "Please download and run the script directly:"
        print_info "  curl -O https://raw.githubusercontent.com/zardoy/minecraft-everywhere/main/deploy.sh"
        print_info "  chmod +x deploy.sh"
        print_info "  ./deploy.sh"
        exit 1
    fi
}

# Check system requirements
check_system() {
    print_step "Checking system requirements..."

    # Check OS
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_error "This script is designed for Linux systems only."
        exit 1
    fi

    # Check required tools
    for tool in curl wget unzip; do
        if ! command -v $tool &> /dev/null; then
            print_error "$tool is required but not installed."
            exit 1
        fi
    done

    print_success "System requirements met."
}

# Interactive menu selection
show_menu() {
    echo -e "${WHITE}Choose Deployment Type:${NC}"
    echo -e " ${GREEN}1)${NC} Minecraft Web Client"
    echo -e " ${YELLOW}2)${NC} Minecraft Websocket Proxy (coming soon)"
    echo -e " ${YELLOW}3)${NC} Pixel Client 1.12.2 (coming soon)"
    echo ""
}

show_deployment_menu() {
    echo -e "${WHITE}How to deploy?${NC}"
    echo -e " ${GREEN}1)${NC} Deploy Outside Docker"
    echo -e " ${YELLOW}2)${NC} Deploy using Docker (coming soon)"
    echo ""
}

show_hosting_menu() {
    echo -e "${WHITE}What to provide?${NC}"
    echo -e " ${GREEN}1)${NC} Node.js proxy server hosting (with PM2)"
    echo -e " ${GREEN}2)${NC} Only static files (Apache/Nginx)"
    echo ""
}

# Get latest release info
get_latest_release() {
    print_step "Fetching latest release information..."

    LATEST_RELEASE=$(curl -s "$API_URL/releases/latest")
    if [[ $? -ne 0 ]]; then
        print_error "Failed to fetch release information."
        exit 1
    fi

    LATEST_VERSION=$(echo "$LATEST_RELEASE" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | grep '"browser_download_url":.*self-host\.zip"' | sed -E 's/.*"([^"]+)".*/\1/')

    if [[ -z "$DOWNLOAD_URL" ]]; then
        print_error "Could not find self-host.zip in latest release."
        exit 1
    fi

    print_info "Latest version: $LATEST_VERSION"
    print_info "Download URL: $DOWNLOAD_URL"
}

# Download and extract release
download_release() {
    print_step "Downloading and extracting release..."

    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    wget -q --show-progress "$DOWNLOAD_URL" -O self-host.zip
    if [[ $? -ne 0 ]]; then
        print_error "Failed to download release."
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    unzip -q self-host.zip
    if [[ $? -ne 0 ]]; then
        print_error "Failed to extract release."
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    print_success "Release downloaded and extracted."
}

# Deploy static files
deploy_static() {
    print_step "Deploying static files..."

    sudo mkdir -p "$STATIC_DIR"
    sudo cp -r dist/* "$STATIC_DIR/"
    sudo chown -R www-data:www-data "$STATIC_DIR" 2>/dev/null || true

    print_success "Static files deployed to $STATIC_DIR"
    print_info "Configure your web server to serve files from $STATIC_DIR"
}

# Check Node.js version
check_nodejs() {
    if ! command -v node &> /dev/null; then
        print_warning "Node.js not found. Installing..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    NODE_VERSION=$(node --version | sed 's/v//')
    MAJOR_VERSION=$(echo $NODE_VERSION | cut -d. -f1)

    if [[ $MAJOR_VERSION -lt 18 ]]; then
        print_error "Node.js 18.x or higher is required. Current version: $NODE_VERSION"
        exit 1
    fi

    print_success "Node.js $NODE_VERSION is installed."
}

# Check and install PM2
check_pm2() {
    if ! command -v pm2 &> /dev/null; then
        print_warning "PM2 not found. Installing..."
        sudo npm install -g pm2
    fi

    print_success "PM2 is installed."
}

# Deploy Node.js server
deploy_nodejs() {
    print_step "Deploying Node.js server..."

    check_nodejs
    check_pm2

    sudo mkdir -p "$INSTALL_DIR"
    sudo cp -r * "$INSTALL_DIR/"
    cd "$INSTALL_DIR"

    # Install dependencies if package.json exists
    if [[ -f package.json ]]; then
        sudo npm install --production
    fi

    # Stop existing service if running
    pm2 delete "$SERVICE_NAME" 2>/dev/null || true

    # Start the service
    pm2 start server.js --name "$SERVICE_NAME"
    pm2 startup
    pm2 save

    print_success "Node.js server deployed and started with PM2."
    print_info "Service name: $SERVICE_NAME"
    print_info "Installation directory: $INSTALL_DIR"
}

# Setup automatic updates
setup_auto_update() {
    print_step "Setting up automatic updates..."

    # Create version directory for both deployment types
    if [[ "$DEPLOYMENT_TYPE" == "static" ]]; then
        VERSION_DIR="/var/lib/minecraft-web-client"
        sudo mkdir -p "$VERSION_DIR"
    else
        VERSION_DIR="$INSTALL_DIR"
    fi

    # Create update script
    UPDATE_SCRIPT="/usr/local/bin/mwc-update.sh"
    sudo tee "$UPDATE_SCRIPT" > /dev/null << EOF
#!/bin/bash

# Minecraft Web Client Auto-Update Script
API_URL="$API_URL"
INSTALL_DIR="$INSTALL_DIR"
STATIC_DIR="$STATIC_DIR"
SERVICE_NAME="$SERVICE_NAME"
DEPLOYMENT_TYPE="$DEPLOYMENT_TYPE"
VERSION_DIR="$VERSION_DIR"

# Get current and latest versions
if [[ -f "\$VERSION_DIR/version" ]]; then
    CURRENT_VERSION=\$(cat "\$VERSION_DIR/version")
else
    CURRENT_VERSION="unknown"
fi

LATEST_RELEASE=\$(curl -s "\$API_URL/releases/latest")
LATEST_VERSION=\$(echo "\$LATEST_RELEASE" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
DOWNLOAD_URL=\$(echo "\$LATEST_RELEASE" | grep '"browser_download_url":.*self-host\.zip"' | sed -E 's/.*"([^"]+)".*/\1/')
RELEASE_BODY=\$(echo "\$LATEST_RELEASE" | grep '"body":' | sed -E 's/.*"body":"([^"]+)".*/\1/')

if [[ "\$CURRENT_VERSION" != "\$LATEST_VERSION" ]]; then
    echo "Updating from \$CURRENT_VERSION to \$LATEST_VERSION"

    # Download and extract
    TEMP_DIR=\$(mktemp -d)
    cd "\$TEMP_DIR"
    wget -q "\$DOWNLOAD_URL" -O self-host.zip
    unzip -q self-host.zip

    # Update files based on deployment type
    if [[ "\$DEPLOYMENT_TYPE" == "static" ]]; then
        # Backup config and custom files
        if [ -f "\$STATIC_DIR/config.json" ]; then
            cp "\$STATIC_DIR/config.json" "\$TEMP_DIR/"
        fi
        # Backup all custom* files
        find "\$STATIC_DIR" -name "custom*" -exec cp {} "\$TEMP_DIR/" \;

        # Update files
        sudo cp -r dist/* "\$STATIC_DIR/"

        # Restore config and custom files
        if [ -f "\$TEMP_DIR/config.json" ]; then
            sudo cp "\$TEMP_DIR/config.json" "\$STATIC_DIR/"
        fi
        # Restore all custom* files
        find "\$TEMP_DIR" -name "custom*" -exec sudo cp {} "\$STATIC_DIR/" \;

        sudo chown -R www-data:www-data "\$STATIC_DIR" 2>/dev/null || true
    else
        sudo cp -r dist/* "\$INSTALL_DIR/dist/"

        # Check if server restart is required
        if echo "\$RELEASE_BODY" | grep -q "requires server restart"; then
            pm2 restart "\$SERVICE_NAME" 2>/dev/null || true
        fi
    fi

    # Update version file
    echo "\$LATEST_VERSION" | sudo tee "\$VERSION_DIR/version" > /dev/null

    echo "Update completed successfully"
    rm -rf "\$TEMP_DIR"
else
    echo "Already up to date (\$CURRENT_VERSION)"
fi
EOF

    sudo chmod +x "$UPDATE_SCRIPT"

    # Save current version
    echo "$LATEST_VERSION" | sudo tee "$VERSION_DIR/version" > /dev/null

    # Setup cron job
    CRON_JOB="0 2 * * * $UPDATE_SCRIPT >> /var/log/mwc-update.log 2>&1"
    (crontab -l 2>/dev/null | grep -v mwc-update; echo "$CRON_JOB") | crontab -

    print_success "Automatic updates configured."
    print_info "Updates will check daily at 2:00 AM"
    print_info "Update logs: /var/log/mwc-update.log"
}

# Check and configure Apache
configure_apache() {
    # Ask for domain configuration
    echo
    read -p "Enter domain name to configure Apache (leave empty to skip): " DOMAIN_NAME

    if [[ -n "$DOMAIN_NAME" ]]; then
        print_step "Configuring Apache web server..."

        # Check if Apache is installed
        if ! command -v apache2 &> /dev/null; then
            print_warning "Apache not found. Installing..."
            sudo apt-get update
            sudo apt-get install -y apache2
        fi

        # Enable required modules
        sudo a2enmod proxy
        sudo a2enmod proxy_http
        sudo a2enmod proxy_wstunnel
        sudo a2enmod rewrite
        sudo a2enmod ssl

        # Create Apache configuration file
        APACHE_CONF="/etc/apache2/sites-available/${DOMAIN_NAME}.conf"

        if [[ "$DEPLOYMENT_TYPE" == "static" ]]; then
            # Static files configuration
            sudo tee "$APACHE_CONF" > /dev/null << EOF
<VirtualHost *:80>
    ServerName ${DOMAIN_NAME}
    ServerAdmin webmaster@localhost
    DocumentRoot ${STATIC_DIR}

    <Directory ${STATIC_DIR}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/${DOMAIN_NAME}_error.log
    CustomLog \${APACHE_LOG_DIR}/${DOMAIN_NAME}_access.log combined
</VirtualHost>
EOF
        else
            # Node.js proxy configuration
            sudo tee "$APACHE_CONF" > /dev/null << EOF
<VirtualHost *:80>
    ServerName ${DOMAIN_NAME}
    ServerAdmin webmaster@localhost

    # Enable proxy settings
    ProxyPreserveHost On

    # Main application proxy rules
    ProxyPass / http://localhost:8080/
    ProxyPassReverse / http://localhost:8080/

    RewriteEngine On
    RewriteCond %{HTTP:Upgrade} websocket [NC]
    RewriteCond %{HTTP:Connection} upgrade [NC]
    RewriteRule ^/?(.*) "ws://localhost:8080/\$1" [P,L]

    # Log files
    ErrorLog \${APACHE_LOG_DIR}/${DOMAIN_NAME}_error.log
    CustomLog \${APACHE_LOG_DIR}/${DOMAIN_NAME}_access.log combined
</VirtualHost>
EOF
        fi

        # Enable the site
        sudo a2ensite "${DOMAIN_NAME}.conf"
        sudo a2dissite 000-default.conf

                # Setup SSL with Certbot
        echo
        read -p "Would you like to setup SSL with Let's Encrypt? (skip if using Cloudflare) [y/N]: " setup_ssl
        setup_ssl=${setup_ssl:-N}

        if [[ $setup_ssl =~ ^[Yy]$ ]]; then
            # Check if certbot is installed
            if ! command -v certbot &> /dev/null; then
                print_warning "Certbot not found. Installing..."
                sudo apt-get update
                sudo apt-get install -y certbot python3-certbot-apache
            fi

            # Get SSL certificate
            print_step "Obtaining SSL certificate from Let's Encrypt..."
            sudo certbot --apache -d "$DOMAIN_NAME" --non-interactive --agree-tos --email "webmaster@${DOMAIN_NAME}" --redirect

            print_success "SSL certificate installed successfully"
        fi

        # Restart Apache
        sudo systemctl restart apache2

        print_success "Apache configured successfully for ${DOMAIN_NAME}"
        if [[ "$DEPLOYMENT_TYPE" == "static" ]]; then
            print_info "Static files will be served from ${STATIC_DIR}"
        else
            print_info "Requests will be proxied to Node.js server on port 8080"
        fi
    else
        print_info "Skipping Apache domain configuration"
    fi
}

# Cleanup
cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

# Main deployment flow
main() {
    trap cleanup EXIT

    print_header
    check_interactive
    check_root
    check_system

    # Main menu
    show_menu
    while true; do
        read -p "Select option [1]: " choice
        choice=${choice:-1}
        case $choice in
            1)
                print_success "Selected: Minecraft Web Client"
                break
                ;;
            2|3)
                print_warning "This option is coming soon!"
                ;;
            *)
                print_error "Invalid option. Please select 1."
                ;;
        esac
    done

    echo

    # Deployment method menu
    show_deployment_menu
    while true; do
        read -p "Select deployment method [1]: " deploy_choice
        deploy_choice=${deploy_choice:-1}
        case $deploy_choice in
            1)
                print_success "Selected: Deploy Outside Docker"
                break
                ;;
            2)
                print_warning "Docker deployment is coming soon!"
                ;;
            *)
                print_error "Invalid option. Please select 1."
                ;;
        esac
    done

    echo

    # Hosting type menu
    show_hosting_menu
    while true; do
        read -p "Select hosting type [1]: " hosting_choice
        hosting_choice=${hosting_choice:-1}
        case $hosting_choice in
            1)
                DEPLOYMENT_TYPE="nodejs"
                print_success "Selected: Node.js proxy server hosting"
                break
                ;;
            2)
                DEPLOYMENT_TYPE="static"
                print_success "Selected: Static files hosting"
                break
                ;;
            *)
                print_error "Invalid option. Please select 1 or 2."
                ;;
        esac
    done

    echo

    # Auto-update option
    read -p "Enable automatic updates from GitHub releases? [Y/n]: " auto_update
    auto_update=${auto_update:-Y}
    if [[ $auto_update =~ ^[Yy]$ ]]; then
        ENABLE_AUTO_UPDATE=true
        print_success "Automatic updates enabled"
    else
        ENABLE_AUTO_UPDATE=false
        print_info "Automatic updates disabled"
    fi

    echo

    # Execute deployment
    get_latest_release
    download_release

    if [[ "$DEPLOYMENT_TYPE" == "static" ]]; then
        deploy_static
    else
        deploy_nodejs
    fi

    if [[ "$ENABLE_AUTO_UPDATE" == true ]]; then
        setup_auto_update
    fi

    echo
    # almost done
    print_success "Almost done..."

    if [[ "$DEPLOYMENT_TYPE" == "static" ]]; then
        print_info "📁 Static files are available at: $STATIC_DIR"
        print_info "🌐 Configure your web server to serve these files"
    else
        print_info "🚀 Node.js server is running with PM2"
        print_info "📊 Check status with: pm2 status"
        print_info "📝 View logs with: pm2 logs $SERVICE_NAME"
        print_info "🔗 The server is running on: http://localhost:8080"
    fi

    if [[ "$ENABLE_AUTO_UPDATE" == true ]]; then
        print_info "🔄 Automatic updates are configured"
        print_info "📅 Updates check daily at 2:00 AM"
    fi

    echo
    # Configure Apache as the last step
    configure_apache

    echo
    print_success "🎉 Deployment completed successfully! 🎮 Happy Gaming! ⛏️"
}

# Run main function
main "$@"
