vagrant-redmine
===============

Basic Vagrant configuration to have a ready to use Redmine site.

>   Note: This is fork of [vagrant-redmine][1] by [clalarco][2] - made mostly to
>   do some cleanups and add configuration for Debian Jessie. Also, by the way
>   I've added the configuration for 32-bit Ubuntu 14.04 and checked that
>   Redmine works well with PostgreSQL. Updated README below.

[1]: <https://github.com/clalarco/vagrant-redmine>

[2]: <https://github.com/clalarco>

It uses Ubuntu 14.04 Trusty Thar or Debian 8.0 Jessie as base system, using
default packages available in official repositories, so at the time of this
writing:

|                | trusty64/trusty-i386 | debian80    |
|:-------------- |:--------------------:|:-----------:|
| **Redmine**    | 2.4.2.stable         | 2.5.2.devel |
| **MySQL**      | 5.5.43               | 5.5.43      |
| **SQLite3**    | 3.8.2                | 3.8.7       |
| **PostgreSQL** | 9.3                  | 9.4         |
| **Apache2**    | 2.4.7                | 2.4.10      |
| **nginx**      | 1.4.6                | 1.6.2       |

It does **not** configure:
- Secure site (yet)
- Use redmine in a subdomain/virtual server


Requirements
------------

**Vagrant**. Download from http://www.vagrantup.com/downloads.html
Version 1.5.1 was used for this configuration.

Note: The included Vagrant version in Ubuntu 12.04 (1.0.1) is not compatible with this configuration. You need to install/update it from .deb installer.

**Virtualbox**, required by Vagrant: https://www.virtualbox.org/wiki/Downloads

Note: For Ubuntu 12.04, the included virtualbox version is enough to perform all vagrant tasks. 


Quick Start up
--------------

1. Install / update Vagrant, from installer file from website.
2. Install virtualbox. From windows, using the installer. From Ubuntu: `sudo apt-get install virtualbox`.
3. Go to vagrant/ directory and write `vagrant up` or `vagrant up name`. You can choose name from `trusty-amd64`, `trusty-i386` or `jessie-amd64`. It will download box if needed and create vm.
4. If vagrant instance was not previously created, it will do the provision from bootstrap.sh.
5. When ready, you can open a browser and go to http://localhost:8888 user: admin, password: admin


Configuration
-------------

In bootstrap.sh you can set:
- Which database to use: sqlite, mysql or postgres
- Which web server to use: nginx or apache2
- Database and Redmine passwords. Notice that these passwords can be set
through this script only when vagrant instance is created.
- Apache2/nginx configuration.
- Extra imagemagick packages if you'd like to install them.


In Vagrantfile you can set:
- Machine cores and memory
- Extra provision scripts you would like to have
- Network type: NAT, bridge (public) or internal
- Port redirection - if you want to use multiple machines simultaneously (i.e. for comparison), you should change the ports from 8888 to something else so they won't conflict
- All the settings available in Vagrant configuration.


TODO
----

- Set up secure mode
- Allow to backup/restore when provisioning instance


References
----------
- Vagrant website: http://www.vagrantup.com/
- How to install Redmine in Ubuntu Step by Step: http://www.redmine.org/projects/redmine/wiki/HowTo_Install_Redmine_on_Ubuntu_step_by_step
- http://www.redmine.org/projects/redmine/wiki/HowTo_configure_Nginx_to_run_Redmine
