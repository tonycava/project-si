#!/bin/bash
sudo apt install nginx -y &&
systemctl start nginx &&
systemctl enable nginx &&
ufw allow http &&
ufw allow https