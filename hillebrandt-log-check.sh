#!/bin/bash
# ------------------------------------------------------------------
#          Title: Hillebrandt Server Log Check
#          Version: 1.1
#          Author: Patricia Hillebrandt
#          Release date: 20-11-2016
#          Latest version: 30-01-2017
#          License: GNU General Public License V3 or later
#          License URI: http://www.gnu.org/licenses/gpl.html
#          Description: This script generates a report listing:
#
#          (From NGINX and/or Apache access log:)
#
#          - The most requested URIs.
#          - The most requested static content.
#
#          (From PHP-fpm access log:)
#
#          - The most requested URIs.
#          - The requests that needed more PHP memory allocated.
#          - The requests that are consuming more of the CPU.
#          - The requests that are taking more time to serve.
#
#          (From php.log:)
#
#          - All Notices, Warnings and Fatal errors from php.log
#            grouped and sorted.
#
#          - Dependencies:
#
#            - Built to work with these log formats:
#
#            * PHP-fpm:
#
#               access.format = "%{mega}MMb %{mili}dms pid=%p %C%% %R - %u %t \"%m %r%Q%q\" %s %f"
#
#            * NGINX log format:
#
#               log_format vhost '$remote_addr - $remote_user [$time_local] '
#                    '"$request" $status $body_bytes_sent '
#                    '"$http_referer" "$http_user_agent" "$proxy_add_x_forwarded_for"' ;
#
#            * Apache log format:
#
#               LogFormat "%a %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\" %D" combined
# ------------------------------------------------------------------
validation() {
    if [[ "$(id -u)" != "0" ]]; then
        echo "root privileges are required to run this script."
        exit 1
    fi
}

choose_site() {
    echo "------------------------------------------------------------------------"
    printf "Type the number of the site you want to verify (press Ctrl-C to cancel):\n"
    echo "------------------------------------------------------------------------"
    cd /var/www/
    listsites=`ls -1`
    listsites+=('All')
    select site in ${listsites[@]}; do
        test -n "$site" && break;
        echo ">>> Invalid Selection";
    done
    echo "==========================================="
    echo "You selected: $site"
    echo "==========================================="
}

# Table Format.
divider===============================
divider=$divider$divider
header="\n %-10s %8s %10s\n"
format=" %-10s %8s %10s\n"
width=43

# Top 10 requested URL.
lebrandt_nginx_most_requested_url() {
    cd /var/log/nginx
    if [[ "$site" = "All" ]]; then
        echo " "
        echo "==========================================="
        echo "$build_type log: Top 5 HTTP requests"
        printf "%$width.${width}s\n" "$divider"

        for log in `find *.access.log -not -empty -ls | awk {'print $11'}`; do
            top_url=`cut -d '"' -f2 $log | cut -d " " -f2 | grep -Ev '\.(jpe?g|gif|ico|zip|pdf|png|css|js)' | sort | uniq -c | sort -nr | head -n 5`
            echo "-------------------------------------------"
            echo "$log"
            echo "-------------------------------------------"
            echo "$top_url"
        done
    else
        top_url=`cut -d '"' -f2 $site.access.log | cut -d " " -f2 | grep -Ev '\.(jpe?g|gif|ico|zip|pdf|png|css|js)' | sort | uniq -c | sort -nr | head`
        echo " "
        echo "-------------------------------------------"
        echo "$build_type log: Top 10 HTTP requests"
        printf "%$width.${width}s\n" "$divider"
        echo "$top_url"
    fi
}

# Top 10 static content requested (images, scripts, etc.).
lebrandt_nginx_most_requested_static() {
    cd /var/log/nginx
    if [[ "$site" = "All" ]]; then
        echo " "
        echo "==========================================="
        echo "$build_type log: Top 5 static content requests"
        printf "%$width.${width}s\n" "$divider"

        for log in `find *.access.log -not -empty -ls | awk {'print $11'}`; do
            top_url=`cut -d '"' -f2 $log | cut -d " " -f2 | grep -E '\.(jpe?g|gif|ico|zip|pdf|png|css|js)' | sort | uniq -c | sort -nr | head -n 5`
            echo "-------------------------------------------"
            echo "$log"
            echo "-------------------------------------------"
            echo "$top_url"
        done
    else
        top_url=`cut -d '"' -f2 $site.access.log | cut -d " " -f2 | grep -E '\.(jpe?g|gif|ico|zip|pdf|png|css|js)' | sort | uniq -c | sort -nr | head`
        echo " "
        echo "-------------------------------------------"
        echo "$build_type log: Top 10 static content requests"
        printf "%$width.${width}s\n" "$divider"
        echo "$top_url"
    fi
}

# Analizes the php-fpm access log and returns the most requested URIs, the requests that demanded more PHP memory, the requests that demanded more of the CPU and
# the requests that took more time to serve.
lebrandt_php_access_log() {
    if [[ "$site" = "All" ]]; then
        site=""
        cd /var/log/
        header="%4s\t%s\t%s\t%s\t%s\n"
        echo " "
        echo "==========================================="
        echo "php-fpm: Top 10 requested URIs"
        echo "==========================================="
        printf "$header" "Nº" "Method" "URI"
        printf "%$width.${width}s\n" "$divider"
        for log in `find php7.0-fpm.*.access.log -not -empty -ls | awk {'print $11'}`; do
            most_requested_uri=`cat $log | awk {'printf ("%4s\t%s\n", $9, $12)'} | sort | uniq -c | sort -nr | head -n 5`
            echo "-------------------------------------------"
            echo "$log"
            echo "-------------------------------------------"
            echo "$most_requested_uri"
        done

        echo " "
        echo "==========================================="
        echo "php-fpm: Top 10 peak memory allocated by PHP"
        echo "==========================================="
        printf "$header" "Nº" "Mem" "Method" "URI"
        printf "%$width.${width}s\n" "$divider"
        for log in `find php7.0-fpm.*.access.log -not -empty -ls | awk {'print $11'}`; do
            peak_memory_allocated=`cat $log | awk {'printf ("%4s\t%s\t%s\n", $1, $9, $12)'} | sort | uniq -c | sort -k2 -nr | uniq -f2 | head -n 5`
            echo "-------------------------------------------"
            echo "$log"
            echo "-------------------------------------------"
            echo "$peak_memory_allocated"
        done
        echo " "
        echo "==========================================="
        echo "php-fpm: Top 10 CPU used by request"
        echo "==========================================="
        printf "$header" "Nº" "CPU" "Method" "URI"
        printf "%$width.${width}s\n" "$divider"
        for log in `find php7.0-fpm.*.access.log -not -empty -ls | awk {'print $11'}`; do
            cpu_used_by_request=`cat $log | awk {'printf ("%4s\t%s\t%s\n", $4, $9, $12)'} | sort | uniq -c | sort -k2 -nr| uniq -f2 | head -n 5`
            echo "-------------------------------------------"
            echo "$log"
            echo "-------------------------------------------"
            echo "$cpu_used_by_request"
        done

        echo " "
        echo "==========================================="
        echo "php-fpm: Top 10 Time taken to serve request (in mili seconds)"
        echo "==========================================="
        printf "$header" "Nº" "Time" "Method" "URI"
        printf "%$width.${width}s\n" "$divider"
        for log in `find php7.0-fpm.*.access.log -not -empty -ls | awk {'print $11'}`; do
            slowest_requests=`cat $log | awk {'printf ("%4s\t%s\t%s\n", $2, $9, $12)'} | sort | uniq -c | sort -k2 -nr | uniq -f2 | head -n 5`
            echo "-------------------------------------------"
            echo "$log"
            echo "-------------------------------------------"
            echo "$slowest_requests"
        done
    else
            most_requested_uri=`grep "$site" /var/log/php7.0-fpm.$site.access.log | awk {'printf ("%4s\t%s\n", $9, $10)'} | sort | uniq -c | sort -nr | head`
            peak_memory_allocated=`cat /var/log/php7.0-fpm.$site.access.log | grep "$site" | awk {'printf ("%4s\t%s\t%s\n", $1, $9, $10)'} | sort | uniq -c | sort -k2 -nr | uniq -f2 | head`
            cpu_used_by_request=`grep "$site" /var/log/php7.0-fpm.$site.access.log | awk {'printf ("%4s\t%s\t%s\n", $4, $9, $10)'} | sort | uniq -c | sort -k2 -nr| uniq -f2 | head`
            slowest_requests=`grep "$site" /var/log/php7.0-fpm.$site.access.log | awk {'printf ("%4s\t%s\t%s\n", $2, $9, $10)'} | sort | uniq -c | sort -k2 -nr | uniq -f2 | head`

            header="%4s\t%s\t%s\t%s\t%s\n"
            echo " "
            echo "==========================================="
            echo "php-fpm: Top 10 requested URIs"
            echo "==========================================="
            printf "$header" "Nº" "Method" "URI"
            printf "%$width.${width}s\n" "$divider"
            echo "$most_requested_uri"

            echo " "
            echo "==========================================="
            echo "php-fpm: Top 10 peak memory allocated by PHP"
            echo "==========================================="
            printf "$header" "Nº" "Mem" "Method" "URI"
            printf "%$width.${width}s\n" "$divider"
            echo "$peak_memory_allocated"

            echo " "
            echo "==========================================="
            echo "php-fpm: Top 10 CPU used by request"
            echo "==========================================="
            printf "$header" "Nº" "CPU" "Method" "URI"
            printf "%$width.${width}s\n" "$divider"
            echo "$cpu_used_by_request"

            echo " "
            echo "==========================================="
            echo "php-fpm: Top 10 Time taken to serve request (in mili seconds)"
            echo "==========================================="
            printf "$header" "Nº" "Time" "Method" "URI"
            printf "%$width.${width}s\n" "$divider"
            echo "$slowest_requests"
    fi
}

# Lists and groups recurring Notices, Warnings and Fatal errors in php.log:
lebrandt_php_log() {
    if [[ "$site" = "All" ]]; then
        site=""
    fi
    errors=("Fatal" "Warning" "Notice")
    cd /var/log

    for error in "${errors[@]}"; do
        phperror=`cut -d ' ' -f7- ./php.log | grep "$site" | egrep "$error" | sort | uniq -c | sort -nr`
        echo " "
        echo "-------------------------------------------"
        echo "PHP $error:"
        printf "%$width.${width}s\n" "$divider"
        echo "$phperror"
    done

    other=`cut -d ' ' -f7- ./php.log | grep "$site" | grep -Ev 'Notice|Fatal|Warning' | sort | uniq -c | sort -nr | head -n 20`
    echo " "
    echo "-------------------------------------------"
    echo "Other errors:"
    printf "%$width.${width}s\n" "$divider"
    echo "$other"
}

validation
choose_site
lebrandt_nginx_most_requested_url
lebrandt_nginx_most_requested_static
lebrandt_php_access_log
lebrandt_php_log