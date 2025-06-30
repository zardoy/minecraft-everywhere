# 🎮 Minecraft Everywhere

> **Self-hosted Minecraft Web Client deployment made simple**

[![GitHub Release](https://img.shields.io/github/v/release/zardoy/minecraft-web-client?style=for-the-badge&logo=github)](https://github.com/zardoy/minecraft-web-client/releases)
[![Docker](https://img.shields.io/badge/Docker-Coming%20Soon-blue?style=for-the-badge&logo=docker)](https://docker.com)

## 🚀 Quick Start

Deploy your own Minecraft Web Client in seconds with our interactive script:

```bash
curl -O https://raw.githubusercontent.com/zardoy/minecraft-everywhere/main/deploy.sh
chmod +x deploy.sh
./deploy.sh
```

## ✨ Features

### 🎯 Available Now
- **🌐 Minecraft Web Client** - Play Minecraft directly in your browser
- **📦 Multiple Deployment Options** - Static files or Node.js server
- **🔄 Automatic Updates** - Stay current with latest releases
- **⚡ Easy Setup** - One command deployment

### 🔮 Coming Soon
- **🔌 Minecraft Websocket Proxy** - Enhanced connectivity
- **🎨 Pixel Client 1.12.2** - Retro Minecraft experience
- **🐳 Docker Support** - Containerized deployment

## 🛠️ Deployment Options

### Option 1: Static Files Only
Perfect for hosting with Apache, Nginx, or any static file server.
- ✅ No server-side processing required
- ✅ Minimal resource usage
- ✅ Easy to maintain

### Option 2: Node.js Proxy Server
Full-featured deployment with server-side capabilities.
- ✅ Enhanced features and performance
- ✅ PM2 process management
- ✅ Automatic service startup
- ✅ Background updates

## 📋 Requirements

### For Static Deployment
- Web server (Apache, Nginx, etc.)
- Basic file serving capabilities

### For Node.js Deployment
- Linux server
- Node.js 18.x or higher
- npm package manager
- PM2 process manager (auto-installed if missing)

## 🔧 Manual Installation

If you prefer manual setup:

1. **Download the latest release:**
   ```bash
   wget $(curl -s https://api.github.com/repos/zardoy/minecraft-web-client/releases/latest | grep "browser_download_url.*self-host.zip" | cut -d '"' -f 4)
   ```

2. **Extract files:**
   ```bash
   unzip self-host.zip
   ```

3. **For static hosting:**
   ```bash
   cp -r dist/* /var/www/html/
   ```

4. **For Node.js hosting:**
   ```bash
   npm install
   pm2 start server.js --name mwc-server
   pm2 startup
   pm2 save
   ```

## 🔄 Automatic Updates

When enabled, the system will:
- ✅ Check for updates every 24 hours
- ✅ Download and apply updates automatically
- ✅ Restart server only when required
- ✅ Maintain service availability

## 🗑️ Uninstallation

To remove Minecraft Web Client from your server:

### For Static Deployment
```bash
# Remove static files
sudo rm -rf /var/www/html/minecraft

# Remove version tracking and update script
sudo rm -rf /var/lib/minecraft-web-client
sudo rm /usr/local/bin/mwc-update.sh

# Remove cron job
(crontab -l | grep -v mwc-update) | crontab -

# If using Apache, remove site configuration
sudo a2dissite minecraft*.conf
sudo rm /etc/apache2/sites-available/minecraft*.conf
sudo systemctl reload apache2

# If SSL was configured, you may want to remove the certificate
sudo certbot delete --cert-name your-domain.com
```

### For Node.js Deployment
```bash
# Stop and remove PM2 service
pm2 stop mwc-server
pm2 delete mwc-server
pm2 save

# Remove installation directory
sudo rm -rf /opt/minecraft-web-client

# Remove update script
sudo rm /usr/local/bin/mwc-update.sh

# Remove cron job
(crontab -l | grep -v mwc-update) | crontab -

# If using Apache, remove site configuration
sudo a2dissite minecraft*.conf
sudo rm /etc/apache2/sites-available/minecraft*.conf
sudo systemctl reload apache2

# If SSL was configured, you may want to remove the certificate
sudo certbot delete --cert-name your-domain.com

# Optionally, if you don't need Node.js and PM2 anymore
sudo npm uninstall -g pm2
# Note: Don't remove Node.js if other applications depend on it
```

Replace `your-domain.com` with the actual domain name you used during installation.

## 🏗️ Project Structure

```
minecraft-everywhere/
├── README.md           # This file
├── deploy.sh          # One-liner deployment script
└── .gitignore         # Git ignore patterns
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🔗 Related Projects

- [Minecraft Web Client](https://github.com/zardoy/minecraft-web-client) - The main web client
- [PrismarineJS](https://github.com/PrismarineJS) - Minecraft protocol implementation

## 💬 Support

Having issues? Please check the [Issues](https://github.com/zardoy/minecraft-everywhere/issues) page or create a new issue.

---

<div align="center">
  <b>🎮 Happy Gaming! ⛏️</b>
</div>
