#!/bin/bash
# sudo apt-get update
# sudo apt install -y apache2 
# sudo systemctl start apache2
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo docker pull kgrbovic/spring-petclinic
sudo docker run -p 80:8080 kgrbovic/spring-petclinic
# cd /var/www/html/
# touch index1.html
# echo '<!DOCTYPE html>' > index.html
# echo '<html>' >> index.html
# echo '<head>' >> index.html
# echo '<title>Level It Up</title>' >> index.html
# echo '<meta charset="UTF-8">' >> index.html
# echo '</head>' >> index.html
# echo '<body>' >> index.html
# echo '<h1>This is a test site hosted on Apache web server</h1>' >> index.html
# echo '</body>' >> index.html
# echo '</html>' >> index.html
# sudo systemctl reload apache2
# sudo systemctl start apache2