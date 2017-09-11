#!/bin/ash

# if not a symlinked settings.php, replace with confd version
if [ ! -h $APACHE_DOCROOT/sites/default/settings.php ]
  then
    /usr/local/bin/confd -onetime -backend env -confdir="/root/drupal$(cat /root/drupal-version.txt)-settings"
fi

if [[ ! -n "$DRUPAL_BASE_URL" ]] ; then
  chmod u+w -R /root/apache_docroot/sites/default
  sed -i '/base_url/d' /root/apache_docroot/sites/default/settings.php
fi
