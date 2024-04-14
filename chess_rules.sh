export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
mkdir /app
cd /app
apt update -y
apt install -y git npm

curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -
sudo apt remove nodejs -y
sudo apt autoremove -y
sudo apt install -y nodejs
node --version

git clone https://github.com/max-lukshitc/wg-api.git
cd wg-api
npm install fastify fastify-static chalk ini
cd ./scripts/bash
chmod 777 installer.sh

vps_ip=$(curl -s ifconfig.co)


sed -i "s/_SERVER_LISTEN=45.34.95.454/_SERVER_LISTEN=$vps_ip/" ../data/wg.def
sed -i 's/_SERVER_PUBLIC_KEY=/_SERVER_PUBLIC_KEY=3yAk0QLFfLPzr5dj87w4xyrjtEAqIw+eVtlpGDW68nE=/' ../data/wg.def
sed -i 's/_SERVER_PRIVATE_KEY=/_SERVER_PRIVATE_KEY=0KxQTrtuC25OWV89GwbXMIH3+U2JDsWZ50GCZljmf1w=/' ../data/wg.def

printf 'y\n\n\n\nyes\nyes\n\n' | ./installer.sh

wg-quick down wg0
rm /etc/wireguard/wg0.conf
./wg.sh -i

systemctl link /app/wg-api/wgapi.service
systemctl start wgapi.service

# Nginx
apt -y install nginx

# Change nginx default file
rm /etc/nginx/sites-available/default
cat <<EOT >> /etc/nginx/sites-available/default
server {
        listen 3000 default_server;
        listen [::]:3000 default_server;
        server_name _;
        location / {
                auth_basic "Administrator’s Area";
                auth_basic_user_file /etc/apache2/.htpasswd;
                proxy_pass http://127.0.0.1:3001;
        }
}
EOT

htpasswd_string="$VPN_PASSWORD"

if [ -z "$htpasswd_string" ]; then
    echo "Error: VPN_HTPASSWD_STRING environment variable is not set"
    exit 1
fi

echo "$htpasswd_string" > /etc/apache2/.htpasswd

systemctl restart nginx
