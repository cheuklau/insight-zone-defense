#!/bin/bash

# Update package manager and get tree package
sudo apt-get update
sudo apt-get install -y tree

# Setup a download and installation directory
HOME_DIR='/home/ubuntu'
INSTALLATION_DIR='/usr/local'
sudo mkdir ${HOME_DIR}/Downloads

# Install Java Development Kit
sudo apt-get install -y openjdk-8-jdk

# Install Python and needed packages
sudo apt-get install -y python-pip python-dev build-essential
sudo pip install configparser
sudo pip install psycopg2
sudo pip install numpy

# Install Boto
sudo pip install boto
sudo pip install boto3

# Install Postgresql and Postgis extension
sudo apt-get install -y postgresql
sudo apt-get install -y postgis

# Log into Postgresql as Postgres
sudo -u postgres psql << EOF
CREATE DATABASE monthlydb;
CREATE USER cheuklau;
ALTER ROLE cheuklau WITH PASSWORD 'insight';
GRANT ALL PRIVILEGES ON DATABASE monthlydb TO cheuklau;
\connect monthlydb;
CREATE EXTENSION Postgis;
EOF

# Install Git and clone repository
sudo apt-get install git-core
git clone https://github.com/cheuklau/insight_devops_airaware.git

# Run DE postgresql application
cd insight_devops_airaware/AirAware/postgres
python create_tables.py
python grid_make.py

# Allow Postgresql to listen to all incoming traffic then restart
sudo sed -i "51i listen_addresses = '*'" /etc/postgresql/9.5/main/postgresql.conf
sudo sed -i '96i host    all             all             0.0.0.0/0               md5' /etc/postgresql/9.5/main/pg_hba.conf
sudo /etc/init.d/postgresql restart
