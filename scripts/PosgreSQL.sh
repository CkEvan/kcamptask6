#!/bin/bash
#installing postgresql and configuring 
sudo apt-get update -y
sudo apt-get install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
sudo -u postgres psql -c "CREATE USER admin WITH PASSWORD 'kc@123#';"
sudo -u postgres psql -c "CREATE DATABASE kcdata OWNER admin;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE kcdata TO admin;"
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf
echo "host all all 0.0.0.0/0 md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf
sudo systemctl restart postgresql
sudo ufw allow 5432/tcp