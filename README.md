
# Hillebrandt Server Log Check

      Version: 1.1
      Author: Patricia Hillebrandt
      Release date: 20-11-2016
      Latest version: 30-01-2017
      License: GNU General Public License V3
      License URI: http://www.gnu.org/licenses/gpl.html

## 1- The Script:

This script was built to help sys-admins to identify performance and critical issues in web servers hosting WordPress installs. You can choose either to analyse a specific website hosted in your server or all sites at once. This script generates the following report list:

(From NGINX access log:)

- The most requested URIs.
- The most requested static content.

(From PHP-fpm access log:)

- The most requested URIs.
- The requests that needed more PHP memory allocated.
- The requests that are consuming more of the CPU.
- The requests that are taking more time to serve.

(From php.log:)

- All Notices, Warnings and Fatal errors from php.log
grouped and sorted.


## 2- Dependencies:

This script was built to work with Ubuntu web servers running Nginx with php-fpm.

Built to work with these log formats:

- PHP-fpm log format:

   access.format = "%{mega}MMb %{mili}dms pid=%p %C%% %R - %u %t \"%m %r%Q%q\" %s %f"

- NGINX log format:

   log_format vhost '$remote_addr - $remote_user [$time_local] '
        '"$request" $status $body_bytes_sent '
        '"$http_referer" "$http_user_agent" "$proxy_add_x_forwarded_for"' ;

## 3- How to install:

- Place this script (hillebrandt-log-check.sh) inside the directory /usr/local/bin/

- Run the following command to activate/allow to execute the script: chmod +x hillebrandt-log-check.sh

- Now you can type hillebrandt-log-check.sh in your terminal and analize your compiled version of server logs!