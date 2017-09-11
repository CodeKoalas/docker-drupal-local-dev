#!/bin/ash

# Run Confd to make config files
/usr/local/bin/confd -onetime -backend env

# Export all env vars containing "_" to a file for use with cron jobs
printenv | grep \_ | sed 's/^\(.*\)$/export \1/g' | sed 's/=/=\"/' | sed 's/$/"/g' > /root/project_env.sh
chmod +x /root/project_env.sh

# Add cron jobs
if [[ -n "$GIT_REPO" ]] ; then
  sed -i "/drush/s/^\w*/$(echo $GIT_REPO | md5sum | grep '[0-5][0-9]' -o | head -1)/" /root/crons.conf
fi
if [[ ! -n "$PRODUCTION" || $PRODUCTION != "true" ]] ; then
  sed -i "/git pull/s/[0-9]\+/5/" /root/crons.conf
fi

# Clone repo to container
git clone --depth=1 -b $GIT_BRANCH $GIT_REPO /var/www/site/

# Create and symlink files folders
mkdir -p /mnt/sites-files/public
mkdir -p /mnt/sites-files/private
chown www-data:www-data -R /mnt/sites-files/public
chown www-data:www-data -R /mnt/sites-files/private
mkdir -p $APACHE_DOCROOT/sites/default
mkdir -p /var/www/site/sync
mkdir -p $APACHE_DOCROOT/sites/default
cd $APACHE_DOCROOT/sites/default && ln -sf /mnt/sites-files/public files
cd /var/www/site/ && ln -sf /mnt/sites-files/private private
chown www-data:www-data -R /var/www/site/sync

# Copy in post-merge script to run composer install
cat /root/post-merge >> /var/www/site/.git/hooks/post-merge
chmod +x /var/www/site/.git/hooks/post-merge

# Run composer install
composer install

# Set DRUPAL_VERSION
echo $(drush --root=$APACHE_DOCROOT status | grep "Drupal version" | awk '{ print substr ($(NF), 0, 1) }') > /root/drupal-version.txt

if [[ -n "$LOCAL" &&  $LOCAL = "true" ]] ; then
  echo "[$(date +"%Y-%m-%d %H:%M:%S:%3N %Z")] NOTICE: Setting up XDebug based on state of LOCAL envvar"
  /usr/bin/apt-get update && apt-get install -y \
    php-xdebug \
    --no-install-recommends && rm -r /var/lib/apt/lists/*
  cp /root/xdebug-php.ini /etc/php/7.0/fpm/php.ini
fi

# Import starter.sql, if needed
/root/mysqlimport.sh

# Create Drupal settings, if they don't exist as a symlink
ln -s $APACHE_DOCROOT /root/apache_docroot
/root/drupal-settings.sh

# Load configs
/root/load-configs.sh

# Hide Drupal errors in production sites
if [[ -n "$PRODUCTION" && $PRODUCTION = "true" ]] ; then
  grep -q -F "\$conf['error_level'] = 0;" $APACHE_DOCROOT/sites/default/settings.php  || echo "\$conf['error_level'] = 0;" >> $APACHE_DOCROOT/sites/default/settings.php
fi

crontab /root/crons.conf
