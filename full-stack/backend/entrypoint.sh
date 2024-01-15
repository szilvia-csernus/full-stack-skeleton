#!/bin/sh

sleep 5 # allowing the postgres server to start up
python manage.py makemigrations
python manage.py migrate --no-input
python manage.py superuser
python manage.py collectstatic --no-input

gunicorn django_project.wsgi:application --bind "0.0.0.0:8000"
