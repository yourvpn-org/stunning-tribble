export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
mkdir /app
cd /app
apt update -y
apt install -y git npm

curl -sL https://deb.nodesource.com/setup_20.x | sudo bash -
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

if [ -z "$2" ]; then
    echo "Error: Public key argument is not provided"
    exit 1
fi

if [ -z "$3" ]; then
    echo "Error: Private key argument is not provided"
    exit 1
fi

# Set the public and private keys
public_key="$2"
private_key="$3"

sed -i "s/_SERVER_LISTEN=45.34.95.454/_SERVER_LISTEN=$vps_ip/" ../data/wg.def
sed -i "s/_SERVER_PUBLIC_KEY=/_SERVER_PUBLIC_KEY=$public_key/" ../data/wg.def
sed -i "s/_SERVER_PRIVATE_KEY=/_SERVER_PRIVATE_KEY=$private_key/" ../data/wg.def

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


if [ -z "$1" ]; then
    echo "Error: Password argument is not provided"
    exit 1
fi

# Set the password for htpasswd
htpasswd_string="$1"
echo "$htpasswd_string"
echo "$htpasswd_string" > /etc/apache2/.htpasswd

systemctl restart nginx
