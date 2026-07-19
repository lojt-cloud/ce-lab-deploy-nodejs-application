#!/bin/bash
# Node.js Application Deployment Script

# Install Node.js
sudo dnf install -y nodejs

# Create app directory and install dependencies
mkdir -p ~/app && cd ~/app
npm init -y
npm install express

# Install PM2 globally
sudo npm install -g pm2

# Start the app under PM2 (assumes app.js and ecosystem.config.js already exist)
pm2 start ecosystem.config.js
pm2 save

# Install and configure Nginx
sudo dnf install -y nginx
sudo systemctl enable --now nginx