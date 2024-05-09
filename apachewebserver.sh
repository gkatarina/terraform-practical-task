#!/bin/bash
sudo apt-get update
sudo apt install -y apache2 
sudo systemctl start apache2
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