#!/bin/bash
sudo su -
apt install nginx -y &&
systemctl start nginx &&
systemctl enable nginx &&
ufw allow http &&
ufw allow https &&

curl -fsSL https://get.docker.com -o get-docker.sh &&
sh get-docker.sh &&

systemctl start docker &&

ufw enable &&
ufw allow 3000/tcp &&
ufw allow 8080/tcp &&

touch /etc/nginx/sites-available/projet-si.conf &&

echo "server {
    listen 80;
    server_name projet-si.lucesf.com;
    location / {
        proxy_pass http://localhost:3000;
    }
}" >> /etc/nginx/sites-available/projet-si.conf &&

docker run -d -p 3000:3000 lucesf/projet-si