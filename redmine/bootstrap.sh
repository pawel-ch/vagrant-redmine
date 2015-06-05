#!/usr/bin/env bash
# Script to create a vagrant image with redmine ready to use.
# @author Claudio Alarcon clalarco@gmail.com

set -x

# Uncomment the selected web server.
USE_NGINX=1
#USE_APACHE2=1

# Uncomment the selected database.
USE_MYSQL=1
#USE_PGSQL=1
#USE_SQLITE3=1

# Uncomment if extra images libraries for redmine will be installed.
#USE_IMAGEMAGICK=1

# Set password. Change at your preference.
DB_PASSWORD='dbpasswd'
REDMINE_PASSWORD='redminepwd'

set +x

PACKAGES=redmine
TMP_SELECTIONS=/tmp/selections

# Set non-interactive installer mode, update repos.
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update

#############################################
# Setup selections, choose packages.
#############################################

# Global redmine selections.
cat > ${TMP_SELECTIONS} <<EOF
redmine redmine/instances/default/app-password password ${REDMINE_PASSWORD}
redmine redmine/instances/default/app-password-confirm password ${REDMINE_PASSWORD}
redmine redmine/instances/default/dbconfig-install boolean true
EOF

function mysql-selections {
  cat >> ${TMP_SELECTIONS} <<EOF
redmine redmine/instances/default/database-type select mysql
redmine redmine/instances/default/mysql/method select unix socket
redmine redmine/instances/default/mysql/app-pass password ${DB_PASSWORD}
redmine redmine/instances/default/mysql/admin-pass password ${DB_PASSWORD}
mysql-server mysql-server/root_password password ${DB_PASSWORD}
mysql-server mysql-server/root_password_again password ${DB_PASSWORD}
EOF
}

function pgsql-selections {
  cat >> ${TMP_SELECTIONS} <<EOF
redmine redmine/instances/default/database-type select pgsql
redmine redmine/instances/default/pgsql/method select unix socket
redmine redmine/instances/default/pgsql/authmethod-admin select ident
redmine redmine/instances/default/pgsql/authmethod-user select ident
redmine redmine/instances/default/pgsql/app-pass password
redmine redmine/instances/default/pgsql/admin-pass password
dbconfig-common dbconfig-common/pgsql/authmethod-admin select ident
dbconfig-common dbconfig-common/pgsql/authmethod-user select ident
EOF
}

function sqlite-selections {
  cat >> ${TMP_SELECTIONS} <<EOF
redmine redmine/instances/default/database-type select sqlite3
redmine redmine/instances/default/db/basepath string /var/lib/dbconfig-common/sqlite3/redmine/instances/default
EOF
}

# Setup database
if [[ -n ${USE_MYSQL} ]]; then
  # Setup mysql-server
  mysql-selections
  PACKAGES="$PACKAGES redmine-mysql"
elif [[ -n ${USE_PGSQL} ]]; then
  # Setup pgsql-server
  pgsql-selections
  PACKAGES="$PACKAGES redmine-pgsql"
elif [[ -n ${USE_SQLITE3} ]]; then
  # Sqlite is installed and used by default as database if no other is set.
  sqlite-selections
fi

# Extras
if [[ -n ${USE_IMAGEMAGICK} ]]; then
  PACKAGES="$PACKAGES imagemagick ruby-rmagick"
fi

cat ${TMP_SELECTIONS} | sudo debconf-set-selections
rm ${TMP_SELECTIONS}

# Setup web servers
if [[ -n ${USE_NGINX} ]]; then
  # Setup nginx and thin
  PACKAGES="$PACKAGES nginx thin"
elif [[ -n ${USE_APACHE2} ]]; then
  # Setup apache2
  PACKAGES="$PACKAGES apache2 libapache2-mod-passenger"
fi

#############################################
# Install packages.
#############################################
if [[ -n ${USE_MYSQL} ]]; then
  # Install mysql-server
  sudo apt-get install -q -y mysql-server --no-install-recommends
elif [[ -n ${USE_PGSQL} ]]; then
  # Install pgsql-server
  sudo apt-get install -q -y postgresql postgresql-contrib --no-install-recommends
fi
# Install all remaining packages
sudo apt-get install -q -y $PACKAGES --no-install-recommends

# Extra required package to make redmine work.
sudo gem install bundler

# Change permissions for redmine directory.
sudo chown www-data:www-data /usr/share/redmine

#############################################
# Configure web servers.
#############################################
# nginx as first option.
# ----------------------
if [[ -n ${USE_NGINX} ]]; then
  # Configure thin.
  CODENAME="`lsb_release -cs`"
  if [ "${CODENAME}" == "trusty" ]; then
    THIN_VER="1.9.1"
  elif [ "${CODENAME}" == "jessie" ]; then
    THIN_VER="2.1"
  fi
  sudo thin config \
    --config /etc/thin${THIN_VER}/redmine.yml \
    --chdir /usr/share/redmine \
    --environment production \
    --servers 2 \
    --socket /tmp/thin.redmine.sock \
    --pid tmp/pids/thin.pid

  # Configure nginx. For now default config is overridden.
  sudo dd of=/etc/nginx/sites-available/default << EOF
upstream redmine_upstream {
        server unix:/tmp/thin.redmine.0.sock;
        server unix:/tmp/thin.redmine.1.sock;
}

server {
        listen 80;
        server_name 127.0.0.1;
        root /usr/share/redmine/public;

        location / {
                try_files \$uri @redmine_ruby;
        }

        location @redmine_ruby {
                proxy_set_header  X-Real-IP  \$remote_addr;
                proxy_set_header  X-Forwarded-For \$proxy_add_x_forwarded_for;
                proxy_set_header  Host \$http_host;
                proxy_redirect off;
                proxy_read_timeout 300;
                proxy_pass http://redmine_upstream;
        }
}    
EOF
  
  # Restart thin
  sudo service thin restart

  # Restart nginx
  sudo service nginx restart

# Else, install apache2.
# ----------------------
elif [[ -n ${USE_APACHE2} ]]; then
  # Link redmine into apache2.
  sudo ln -s /usr/share/redmine/public /var/www/redmine

  # Override apache settings.
  sudo dd of=/etc/apache2/sites-available/000-default.conf <<EOF
<VirtualHost *:80>
      ServerAdmin webmaster@localhost
      DocumentRoot /var/www/redmine
      ErrorLog ${APACHE_LOG_DIR}/error.log
      CustomLog ${APACHE_LOG_DIR}/access.log combined
      <Directory /var/www/redmine>
              RailsBaseURI /
              PassengerResolveSymlinksInDocumentRoot on
      </Directory>
</VirtualHost>
EOF

  # Configure passenger
  sudo dd of=/etc/apache2/mods-available/passenger.conf <<EOF
<IfModule mod_passenger.c>
PassengerDefaultUser www-data
PassengerRoot /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini
PassengerDefaultRuby /usr/bin/ruby
</IfModule>
EOF

  # Configure security messages.
  sed -i 's|Server Tokens .*|Server Tokens Prod|g' /etc/apache2/conf-available/security.conf

  # Restart apache2
  sudo service apache2 restart
fi

cat <<EOF
################################################
# Now you should be able to see redmine webpage
# http://localhost:8888
################################################
EOF
