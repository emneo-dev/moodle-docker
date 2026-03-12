#!/usr/bin/env sh

set -e

: ${MOODLE_SITE_FULLNAME:=Moodle}
: ${MOODLE_SITE_SHORTNAME:=Moodle}
: ${MOODLE_SITE_LANG:=en}
: ${MOODLE_ADMIN_USER:=admin}
: ${MOODLE_ADMIN_PASS:=admin}
: ${MOODLE_ADMIN_EMAIL:=admin@example.com}
: ${MOODLE_DB_TYPE:=pgsql}
: ${MOODLE_ENABLE_SSL:=false}
: ${MOODLE_UPDATE:=false}

if [ -z "$MOODLE_DB_HOST" ]; then
	echo >&2 'error: missing MOODLE_DB_HOST environment variable'
	echo >&2 '	Did you forget to --link your database?'
	exit 1
fi

if [ -z "$MOODLE_DB_USER" ]; then
	echo >&2 'error: missing required MOODLE_DB_USER environment variable'
	exit 1
fi

if [ -z "$MOODLE_DB_PASSWORD" ]; then
	echo >&2 'error: missing required MOODLE_DB_PASSWORD environment variable'
	echo >&2 '	Did you forget to -e MOODLE_DB_PASSWORD=... ?'
	echo >&2
	echo >&2 '	(Also of interest might be MOODLE_DB_USER and MOODLE_DB_NAME)'
	exit 1
fi

: ${MOODLE_DB_NAME:=moodle}

if [ -z "$MOODLE_DB_PORT" ]; then
	echo >&2 'error: missing required MOODLE_DB_PORT environment variable'
	exit 1
fi

# Wait for the DB to come up
while [ `/bin/nc -w 1 $MOODLE_DB_HOST $MOODLE_DB_PORT < /dev/null > /dev/null; echo $?` != 0 ]; do
    echo "Waiting for $MOODLE_DB_TYPE database to come up at $MOODLE_DB_HOST:$MOODLE_DB_PORT..."
    sleep 1
done
echo "Database is up and running."

export MOODLE_DB_TYPE MOODLE_DB_HOST MOODLE_DB_USER MOODLE_DB_PASSWORD MOODLE_DB_NAME

cd /var/www/html

: ${MOODLE_SHARED:=/moodledata}
if [ ! -d "$MOODLE_SHARED" ]; then
    echo "Created $MOODLE_SHARED directory."
    mkdir -p $MOODLE_SHARED
fi

# Install database if installed file doesn't exist
if [ ! -e "$MOODLE_SHARED/installed" -a ! -f "$MOODLE_SHARED/install.lock" ]; then
    echo "Moodle database is not initialized. Initializing..."
    touch $MOODLE_SHARED/install.lock
    sudo -E -u www-data php admin/cli/install_database.php \
        --agree-license \
        --lang "$MOODLE_SITE_LANG" \
        --adminuser=$MOODLE_ADMIN_USER \
        --adminpass=$MOODLE_ADMIN_PASS \
        --adminemail=$MOODLE_ADMIN_EMAIL \
        --fullname="$MOODLE_SITE_FULLNAME" \
        --shortname="$MOODLE_SITE_SHORTNAME"
    if [ -n $SMTP_HOST ]; then
        sudo -E -u www-data php admin/cli/cfg.php --name=smtphosts --set=$SMTP_HOST
    fi
    if [ -n $SMTP_USER ]; then
        sudo -E -u www-data php admin/cli/cfg.php --name=smtpuser --set=$SMTP_USER
    fi
    if [ -n $SMTP_PASS ]; then
        sudo -E -u www-data php admin/cli/cfg.php --name=smtppass --set=$SMTP_PASS
    fi
    if [ -n $SMTP_SECURITY ]; then
        sudo -E -u www-data php admin/cli/cfg.php --name=smtpsecure --set=$SMTP_SECURITY
    fi
    if [ -n $SMTP_AUTH_TYPE ]; then
        sudo -E -u www-data php admin/cli/cfg.php --name=smtpauthtype --set=$SMTP_AUTH_TYPE
    fi
    if [ -n $MOODLE_NOREPLY_ADDRESS ]; then
        sudo -E -u www-data php admin/cli/cfg.php --name=noreplyaddress --set=$MOODLE_NOREPLY_ADDRESS
    fi

    touch $MOODLE_SHARED/installed
    rm $MOODLE_SHARED/install.lock
    echo "Done."
fi

# Run additional init scripts
DIR=/docker-entrypoint.d

if [[ -d "$DIR"  ]]
then
    /bin/run-parts --verbose "$DIR"
fi

exec "$@"
