#!/bin/bash
set -e

# dependencies
apt-get update -y
apt-get install -y apache2 curl

# start/enable apache
systemctl start apache2
systemctl enable apache2

# create image directory
mkdir -p /var/www/html/images

# fetch gif
curl -L --retry 3 --retry-delay 5 \
  "https://github.com/torerodev/showtime/blob/main/img/showtime.gif?raw=true" \
  -o "/var/www/html/images/showtime.gif" || {
    echo "Failed to download GIF"
    exit 1
  }

# write html file
cat > /var/www/html/index.html << 'EOF'
${html_content}
EOF

# set permissions
chmod -R 755 /var/www/html

echo "GIF webserver setup complete."