# Nginx-EE virtual host configuration file
# @author    nystudio107, Augustine Calvino, Christopher Hartung
# @copyright Copyright (c) 2016 nystudio107
# @link      https://nystudio107.com/
# @package   nginx-craft
# @since     1.0.0
# @license   MIT

# Bots to ban via user agent
map $http_user_agent $limit_bots {
     default 0;
     ~*(AhrefsBot|Baiduspider|PaperLiBot) 1;
}

# Primary virtual host server block
server {
    server_name SOMEDOMAIN;
    listen [::]:443 ssl http2;
    listen 443 ssl http2;

    if ($host != SOMEDOMAIN) {
        return 404;
    }

    root "/var/www/SOMEDOMAIN";
    index index.html index.htm index.php;
    charset utf-8;

    # Ban certain bots from crawling the site
    if ($limit_bots = 1) {
        return 403;
    }

    # 404 error handler
    error_page 404 /index.php?$query_string;

    # 301 Redirect URLs with trailing /'s as per https://webmasters.googleblog.com/2010/04/to-slash-or-not-to-slash.html
    rewrite ^/(.*)/$ /$1 permanent;

    # Change // -> / for all URLs, so it works for our php location block, too
    merge_slashes off;
    rewrite (.*)//+(.*) $1/$2 permanent;

    # Disable reading of Apache .htaccess files
    location ~ /\.ht {
        deny all;
    }

    # For WordPress bots/users
    location ~ ^/(wp-login|wp-admin|wp-config|wp-content|wp-includes|xmlrpc) {
        return 301 https://wordpress.com/wp-login.php;
    }

    # Handle Do Not Track as per https://www.eff.org/dnt-policy
    location /.well-known/dnt-policy.txt {
        try_files /dnt-policy.txt /index.php?p=/dnt-policy.txt;
    }

    # Access and error logging
    access_log off;
    error_log  /var/log/nginx/error.log error;
    # If you want error logging to go to SYSLOG (for services like Papertrailapp.com), uncomment the following:
    #error_log syslog:server=unix:/dev/log,facility=local7,tag=nginx,severity=error;

    # Load configuration files from snippets
    include /etc/nginx/snippets/compression.conf;
    include /etc/nginx/snippets/expires.conf;

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
        fastcgi_param HTTP_HOST SOMEDOMAIN;

        # Don't allow browser caching of dynamically generated content
        add_header Last-Modified $date_gmt;
        add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";
        if_modified_since off;
        expires off;
        etag off;

        include /etc/nginx/snippets/security.conf;

        # Use Dotenvy to generate the .env variables as per: https://github.com/nystudio107/dotenvy
        # and then uncomment this line to include them:
        # include /home/forge/SOMEDOMAIN/.env_nginx.txt

        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    # Enable server-side includes as per: http://nginx.org/en/docs/http/ngx_http_ssi_module.html
    ssi on;
    # Disable limits on the maximum allowed size of the client request body
    client_max_body_size 0;
    # Don't send the nginx version number in error pages and Server header\
    server_tokens off;

    include /etc/nginx/snippets/ssl.conf;
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
}

server {
    listen 80;
    listen [::]:80;
    server_name SOMEDOMAIN;

    if ($host ~ SOMEDOMAIN) {
        return 301 https://$host$request_uri;
    }

    return 404;

    server_tokens off;
}
