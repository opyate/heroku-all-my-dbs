#!/usr/bin/env bash

APPS_LIST=apps.json
touch $APPS_LIST

if [ ! -f $APPS_LIST ]; then
	echo "Querying Heroku for apps..."
	heroku list -A --json | jq -r '.[].name'> $APPS_LIST
fi

BASE=apps
mkdir -p $BASE

for APP in $(cat $APPS_LIST); do
	APPFILE=$BASE/$APP
	if [ ! -f $APPFILE ]; then
		touch $APPFILE
		heroku pg:info -a $APP > $APPFILE
	fi
	if grep -q "has no heroku-postgresql databases" $APPFILE; then
		echo "👎  No db for $APP"
	else
		TABLEFILE=$BASE/${APP}.tables
		if [ ! -f $TABLEFILE ]; then
			heroku pg:psql -a $APP -c "\dt" > $TABLEFILE
		fi
		if grep -q "No relations found." $TABLEFILE; then
			echo "👎  No relations for $APP"
		else
			echo "❤ Relations for $APP"
			cat $TABLEFILE
		fi
	fi
done
