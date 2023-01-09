# nginx-craft

An Nginx virtual host configuration for Craft CMS that implements a number of best-practices.

## Overview

### What it handles

The Nginx-Craft configuration handles:

* Redirecting from HTTP to HTTPS
* Canonical domain rewrites from SOMEDOMAIN to www.SOMEDOMAIN
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

* The site and its subdomains use https
* The site is managed at cloudflare
* The canonical domain is www.SOMEDOMAIN
* Nginx is version 1.22 or later, from the ubuntu package maintained by ondrej (or otherwise has brotli support compiled in)
* Paths are standard Ubuntu
* You're using php8.2 via php-fpm
* You have `'omitScriptNameInUrls' => true,` in your `craft/general.php`

If any of these assumptions are invalid, make the appropriate changes.

### What's included

This Nginx configuration comes in two parts:

* `sites-available/somedomain.com` - an Nginx virtual host configuration file tailored for Craft CMS; it will require some minor customization for your domain
* `snippets` - some Nginx configuration snippets used by all of the virtual hosts, logically segregated.  These don't need to be changed, but can be selectively disabled by not including them.

## Using Nginx-Craft

> **Warning**
> For any sections involving HSTS, be sure that your domain _and all its subdomains_ are and will be accessible via https. If you are not sure or don't understand this feature, do not proceed!

### On Cloudflare

1. Configure SSL mode
    * Go to Cloudflare > yourdomain > SSL/TLS
    * Select "Full (strict)"
1. Obtain an SSL certificate for your domain
    * Go to Cloudflare > yourdomain > SSL/TLS > Origin Server
    * If site host certificate is already created, check 1Pass for cert and private key
    * Otherwise, "Create Certificate", select "ECC" as the key type, "Create", then save cert and private key in 1Pass
1. Configure SSL settings
    * Go to Cloudflare > yourdomain > SSL/TLS > Edge Certificates
    * Toggle "Always Use HTTPS" on
    * Enable HSTS - toggle all options on and set `max-age` to 1 year
    * Set "Minimum TLS Version" to 1.2
    * Toggle "Opportunistic Encryption" on
    * Toggle "TLS 1.3" on
    * Toggle "Automatic HTTPS Rewrites" on

### On Server

1. Upload fullchain certificate and private key to `/etc/nginx/ssl/` as `fullchain.pem` and `privkey.pem`, respectively
1. Upload `cloudflare.pem` (the issuer certificate) and `dhparams.pem` to `/etc/nginx/ssl/`; these are required for ssl stapling and key-exchange protocols, respectively
1. Upload the entire `snippets` folder to `/etc/nginx/snippets`
1. Rename the `somedomain.com` file to `yourdomain.com` and upload to `/etc/nginx/sites-available`
1. Do a search & replace in `yourdomain.com` to change `SOMEDOMAIN` -> `yourdomain`
1. Change the `fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;` line to reflect whatever version of PHP you're running
1. Restart nginx via `sudo nginx -s reload`

### Additional

* Go to <https://hstspreload.org/> and submit domain name for preloading

## Local Development

Normally we will use `ddev` for local development, which handles nginx configuration, but if you like bringing pain upon yourself, feel free to read on.

--------

While all of the configuration in the `somedomain.com` will work fine in local development as well, some people might want a simpler setup for local development.

There is a `basic_localdev.com` that you can use for a basic Nginx configuration that will work with Craft without any of the bells, whistles, or optimizations found in the `somedomain.com`.

While this is suitable for getting up and running quickly for local development, do not use it in production. There are a number of performance optimizations missing from it.
