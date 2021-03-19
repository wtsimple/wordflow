# Wordflow
An attempt for a modern WordPress with enough development-production parity

Based on
- Docker
- [Rocketstack](https://www.wpintense.com/2018/10/20/installing-the-fastest-wordpress-stack-ubuntu-18-mysql-8/) 
- WP Bedrock by Roots

## Requirements
- git
- Docker and docker-compose
- PHP composer
- PHP extensions in the host (some more could show up)
    - xml `sudo apt install php7.x-xml`
    - zip `sudo apt install php7.x-zip`

## Installation

Now let's explain how to get you started with the stack. It could be as quick as 10-15 minutes if you have a fast network and everything goes without error.

### Docker

Install [Docker](https://docs.docker.com/get-docker/) and [docker-compose](https://docs.docker.com/compose/install/)

In Debian based linux distributions it might be enough just to do

```sh
sudo apt install docker docker-compose
```

### PHP dependencies

Install PHP [Composer](https://getcomposer.org/doc/00-intro.md)

Clone the repository

```sh
git clone https://github.com/ArmandoRiveroPi/wordflow
```

Install the dependencies with Composer

```sh
cd bedrock && composer install
```

### Launch the containers

There are two `.env` files you'll need to create before you run your WordPress site, one for Docker and the other for Bedrock.

You will see in the root directory a `.env.example` file. You should copy it into a `.env` file and edit it. When you create your MySQL Docker image, Docker will use the parameters in this `.env` file to set the root password and to create a new MySQL user that will own the database intended for WP. In my opinion, the data should go into an external Docker volume, otherwise it will be lost forever if you do `docker-compose down`. Once you create the MySQL image and put the database into the volume, you cannot change the credentials simply by editing the `.env` file, though. You'll either need to destroy the volume an rebuild the image, or change the credentials inside MySQL with an `ALTER USER` query.

I called the volume `wordflow_data` but you can name it any way you want, just remember to edit the `docker-compose.yml` accordingly. You can create the volume with

```sh
docker volume create --name=wordflow_data
```

After you have the volume, move into the `bedrock` directory, there should also be an `bedrock/.env.example` file you can copy into `bedrock/.env`. You'll see the usual WP stuff like database credentials and the security salts that you need to fill. Also, you'll see the parameter `WP_ENV` which is part of the Bedrock genius, because you can use it to separate production, staging and development environments. Anywhere within your code you can check for instance `if(defined('WP_ENV') && WP_ENV === 'production')` and you can take special actions per environment.

At this point you can build the Docker images running this

```sh
cd <directory with docker-compose.yml>
docker-compose up -d
```

It should take a few minutes to download the base images and build them.

If you didn't get any errors, your site should be available in <http://localhost>. A nice trick, of course, is to edit your `/etc/hosts` file (or the Windows equivalent) so you can develop using a pretty url like <http://mygreatsite.dev>. HTTPS is also enabled, but with a self signed certificate that you'd need to explicitly accept in your browser.

The first time you open the URL you will be welcomed by the WordPress "famous 5 minutes installation" screen.

One of the surprises Bedrock will give you is that the admin url is at <http://localhost/wp/wp-admin>
instead of <http://localhost/wp-admin>.

## How to use

So, now you have the site running and you're eager to start developing? This is how you go

### Developing themes and plugins

Bedrock uses a `web` directory with two subdirectories: `bedrock/web/wp` and `bedrock/web/app`. The first, `wp` is for the default WordPress installation an is managed by Composer. You shouldn't touch this. Composer will erase it when upgrading WP versions. Instead, your code should go in `bedrock/web/app`, which is the WordPress content directory (what will usually go into `wp-content`). Just put your themes into `app\themes` and your plugins into `app\plugins` and start coding.

You'll also notice that the plugins you install with Composer (I'll explain how bellow) go into `app\plugins` as well. These plugins are also managed by Composer and shouldn't be touched. In general you leave all installations and upgrades of PHP packages up to Composer to make your stack reproducible in all hosts.

### Install a plugin, theme or a different version of WordPress

You might know the way Composer works. You have a `composer.json` that describes the version of each dependence that you want. When you change this file, you can run

```sh
cd <to the folder with your composer.json>
composer update
```

This will put your dependencies exactly in the state described by `composer.json` installing what's needed and removing what's not.

To install plugins or different WordPress versions you need to include them in this section of the json

```json
    "require": {
        "php": ">=7.1",
        "composer/installers": "^1.8",
        "vlucas/phpdotenv": "^4.1.8",
        "oscarotero/env": "^2.1",
        "roots/bedrock-autoloader": "^1.0",
        "roots/wordpress": "^5.7",
        "roots/wp-config": "1.0.0",
        "roots/wp-password-bcrypt": "1.0.0",
        "rhubarbgroup/redis-cache": "^2.0",
        "wpackagist-plugin/nginx-cache": "^1.0"
    }
```

The line that describes the WP version is `"roots/wordpress": "^5.7",`. The expression `^5.7` means the latest `5.7.x` version. When you run `composer update` even if you don't touch that line, Composer will check if there's a newer `5.7.x` WordPress version in the Roots repository and will install it. This is recommended because minor versions usually bring bug fixes and security patches that you want to have ASAP. Also minor updates should never break your site. However, keep in mind that dependencies changes, like code changes, should always flow from development to production, testing them first locally before pushing them to the live site.

The plugins come courtesy of [WP Packagist](https://wpackagist.org/), a great project that makes WordPress themes and plugins available as Composer packages. For instance, if you wanted to install Ninja Forms, you'd (1) find the plugin slug `ninja-forms` and the latest version `^3.5` in the WP plugin directory, (2) add it to your requirements section `"wpackagist-plugin/ninja-forms": "^3.5"` (3) run `composer update` and (4) activate the plugin in the WP admin interface. When you use Bedrock, DO NOT EVER install a plugin directly via the WP admin.

### Dump the database

You can use any tools you want, maybe a general purpose SQL client. I'll just leave you here the native MySQL way through the command `mysqldump`

```sh
mysqldump -h localhost -u username -p --protocol TCP databasename > dump.sql
```

The `--protocol` parameter is important because, although your database is accessible at localhost, it's not directly running in the host OS as MySQL would expect and hence cannot be accessed through a system socket.

### Have different configurations per environment

You have probably seen the `bedrock/config` folder. The `application.php` file there is a configuration file where you can set constants and do whatever needed to dictate the behavior of your application. `bedrock/config/application.php` is always executed regardless of your `WP_ENV`, but the files in `bedrock/config/environments` are environment-dependent, for instance `development.php` will only be executed when `WP_ENV == 'development'` and so on. Hence, you can have your PHP configuration files per each environment there. For the sake of security, you should also have different `.env` and `bedrock/.env` files per environment, with different passwords and salts. And don't forget to set `WP_ENV` appropriately at `bedrock/.env`.

## Do it yourself

I'm far from a genius, so if I could do it, you can also create your dockerized high performance WordPress stack, and it might be even better. I would recommend to read the [Rocketstack article](https://www.wpintense.com/2018/10/20/installing-the-fastest-wordpress-stack-ubuntu-18-mysql-8/) and also read about [Bedrock](https://roots.io/bedrock/). On the other hand, if you just want to make a tweak to Wordflow, I'd be more than happy to listen to you. Please, create an issue, pull request or open a discussion at [the github repo](https://github.com/ArmandoRiveroPi/wordflow) or just leave your comment here and I'll get in touch. This is actually my first open source code that might be used by somebody (it's so coooool)

## Still missing

This project is still very fresh and will need a lot more work to support more features and gain robustness. Just a few things from the top of my head:

- SSL with Letsencrypt (there are some instructions in the Rocketstack article). It's easy to change the nginx configuration to use the certificates you have, but I still need to figure out how to generate them automatically and renew them with Letsencrypt `certbot`.
- Automated tests, maybe something with phpunit and codeception
