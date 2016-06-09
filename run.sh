#!/bin/bash

php -c /etc/php/cli /var/www/app/WebSocket/websocket.php >/var/log/websocket.log 2>/var/log/websocket.err &

rm -f /run/apache2/apache2.pid
exec /usr/sbin/apache2ctl -D FOREGROUND