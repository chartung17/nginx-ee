# nginx-craft

An Nginx virtual host configuration for Craft CMS that implements a number of best-practices.

## Overview

### What it handles

The Nginx-Craft configuration handles:

* Redirecting from HTTP to HTTPS
* Canonical domain rewrites from SOMEDOMAIN.com to www.SOMEDOMAIN.com
* 301 Redirect URLs with trailing /'s as per <https://webmasters.googleblog.com/2010/04/to-slash-or-not-to-slash.html>
* Setting `PATH_INFO` properly via php-fpm -> PHP
* Setting `HTTP_HOST` to mitigate [HTTP_HOST Security Issues](https://expressionengine.com/blog/http-host-and-server-name-security-issues)
* "Far-future" Expires headers
* Enable serving of static brotli files via `brotli_static`
* Adding XSS and other security headers
* Brotli compression
* Filename-based cache busting for static resources
* IPv4 and IPv6 support
* http2 support
* Reasonable SSL cipher suites and TLS protocols
* Localized sites
* Server-side includes
* Optionally includes [Dotenvy](https://github.com/nystudio107/dotenvy) generated `.env` files

### Assumptions made

The following are assumptions made in this configuration:

* The site is https
* The SSL certificate is from LetsEncrypt.com
* The canonical domain is www.SOMEDOMAIN
* Nginx is version 1.9.5 or later (and thus supports http2)
* Paths are standard Ubuntu, change as needed
* You're using php8.2 via php-fpm
* You have `'omitScriptNameInUrls' => true,` in your `craft/general.php`

If any of these assumptions are invalid, make the appropriate changes.

### What's included

This Nginx configuration comes in two parts:

* `sites-available/somedomain.com.conf` - an Nginx virtual host configuration file tailored for Craft CMS; it will require some minor customization for your domain
* `snippets` - some Nginx configuration snippets used by all of the virtual hosts, logically segregated.  These don't need to be changed, but can be selectively disabled by not including them.

## Using Nginx-Craft

### Configuring ssl

1. Obtain


### Always

1. Obtain an SSL certificate for your domain via Cloudflare > yourdomain > SSL/TLS > Origin Server > Create Certificate, and upload cert and private key to `/etc/nginx/certs/yourdomain/`
2. [Install Certbot](https://certbot.eff.org/instructions?ws=nginx&os=ubuntufocal) (creates a `dhparams.pem` and manages some ssl defaults)
3. Upload `cloudflare.pem` (the issuer certificate) to `/etc/nginx/certs/`. This is required for ssl stapling
4. Upload the entire `snippets` folder to `/etc/nginx/snippets`
5. Rename the `somedomain.com.conf` file to `yourdomain.com` and upload to `/etc/nginx/sites-available`
6. Do a search & replace in `yourdomain.com` to change `SOMEDOMAIN` -> `yourdomain`
7. Change the `fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;` line to reflect whatever version of PHP you're running
8. Restart nginx via `sudo nginx -s reload`

## Local Development

Normally we will use `ddev` for local development, which handles nginx configuration, but if you like bringing pain upon yourself, feel free to read on.

--------

While all of the configuration in the `somedomain.com.conf` will work fine in local development as well, some people might want a simpler setup for local development.

There is a `basic_localdev.com.conf` that you can use for a basic Nginx configuration that will work with Craft without any of the bells, whistles, or optimizations found in the `somedomain.com.conf`.

While this is suitable for getting up and running quickly for local development, do not use it in production. There are a number of performance optimizations missing from it.

Brought to you by [nystudio107](https://nystudio107.com/)
