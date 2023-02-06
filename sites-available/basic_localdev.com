# Nginx-EE virtual host configuration file
# @author    nystudio107, Christopher Hartung
# @copyright Copyright (c) 2016 nystudio107
# @link      https://nystudio107.com/
# @package   nginx-craft
# @since     1.0.11
# @license   MIT

# This is a BASIC Nginx config for ExpressionEngine, suitable for use in for local development
# DO NOT use this config in production, it is not performant. Instead, use the
# somedomain.com config
server {
    # Listen for both IPv4 & IPv6 on port 80
    listen 80;
    listen [::]:80;

    # General virtual host settings
    server_name SOMEDOMAIN.com;
    server_tokens off;
    root "/var/www/SOMEDOMAIN/web";
    index index.html index.htm index.php;
    charset utf-8;

    # Enable server-side includes as per: http://nginx.org/en/docs/http/ngx_http_ssi_module.html
    ssi on;

    # Disable limits on the maximum allowed size of the client request body
    client_max_body_size 0;

    # 404 error handler
    error_page 404 /index.php?$query_string;

    # Access and error logging
    access_log off;
    error_log  /var/log/nginx/SOMEDOMAIN.com-error.log error;
    # If you want error logging to go to SYSLOG (for services like Papertrailapp.com), uncomment the following:
    #error_log syslog:server=unix:/dev/log,facility=local7,tag=nginx,severity=error;

    # Root directory location handler
    location / {
        try_files $uri /index.php$is_args$args;
    }

    # php-fpm configuration
    location ~ [^/]\.php(/|$) {
        try_files $uri $uri/ /index.php?$query_string;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        # Change this to whatever version of php you are using
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT $realpath_root;
        fastcgi_param HTTP_PROXY "";
        fastcgi_param HTTP_HOST SOMEDOMAIN.com;

        # Use Dotenvy to generate the .env variables as per: https://github.com/nystudio107/dotenvy
        # and then uncomment this line to include them:
        # include /home/forge/SOMEDOMAIN/.env_nginx.txt

        # Don't allow browser caching of dynamically generated content
        add_header Last-Modified $date_gmt;
        add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";
        if_modified_since off;
        expires off;
        etag off;

        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    # Disable reading of Apache .htaccess files
    location ~ /\.ht {
        deny all;
    }

    # Misc settings
    sendfile off;
}
