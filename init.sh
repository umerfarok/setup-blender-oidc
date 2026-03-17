#!/bin/bash

# Exit on error
set -e

echo "Starting Guacamole environment initialization..."

# Step 1: Prepare the directories
echo "Creating data and extensions directories..."
mkdir -p ./data
mkdir -p ./extensions

# Step 2: Generate the PostgreSQL Database Initialization script
echo "Generating initdb.sql..."
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --postgresql > ./data/initdb.sql

# Step 3: Download the OpenID (Google Auth) Extension
echo "Downloading Google Auth SSO extension..."
cd ./extensions
wget -q https://archive.apache.org/dist/guacamole/1.5.5/binary/guacamole-auth-sso-1.5.5.tar.gz
tar -xf guacamole-auth-sso-1.5.5.tar.gz
mv guacamole-auth-sso-1.5.5/openid/guacamole-auth-sso-openid-1.5.5.jar .
rm -rf guacamole-auth-sso-1.5.5*
cd ..

echo "Initialization complete! You can now run 'docker-compose up -d'."
