#!/bin/bash -li

# source custom env variables
# avoid overwriting env variables set using '-e' or '--env-file' on docker run
# https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e-env-env-file

# backups current environment
# WARN: docker's --env-file parameters doesnt interpret the env file in a bash-like way
# see this issue: https://github.com/moby/moby/issues/26009
# we decide to unescape first and last double quotes (we leave the remaining as is)
# we also unescape ALL $ signs
declare -px | sed -e 's/"\\"/"/g; s/\\""/"/g; s/\\\$/\$/g' > /tmp/current.env

# backup original name because it will be overwriten by default config
ORIGINAL_DEVICE_CODENAME=$DEVICE_CODENAME

# set all sourced variables to be automatically exported
# https://unix.stackexchange.com/a/79077/244937
set -o allexport

# loads default env file
source /etc/profile.d/default.env

# try to load load one of the existing configurations based on $DEVICE_CODENAME set before
CONFIG_FILENAME="$DEVICE_CONFIGS_DIR/$ORIGINAL_DEVICE_CODENAME.env"
if [ -f "$CONFIG_FILENAME" ]; then
	source $CONFIG_FILENAME
fi

set +o allexport
# any variable that was set before will now go back in place :)
source /tmp/current.env
rm -f /tmp/current.env

# remounting $BASE_DIR without noexec option
if cat /proc/mounts | grep $BASE_DIR | grep -q 'noexec'; then
	sudo mount -o remount,exec $BASE_DIR
	# fixes permissions for mounted dir
	sudo chown $USER -R $BASE_DIR
fi

# add colored alias to ls
alias ls='ls --color'

# add a alias so source is done automagically
alias lineageos='source /bin/lineageos'