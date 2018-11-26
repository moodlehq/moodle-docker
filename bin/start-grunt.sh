#!/usr/bin/env bash

until cd /var/www/html && npm install
do
    echo "Retrying npm install"
done
grunt watch
