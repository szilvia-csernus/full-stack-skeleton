#!/bin/sh

# allowing the postgres server to start up
sh ./wait-for-postgres.sh db python manage.py makemigrations
python manage.py migrate --no-input
python manage.py superuser
python manage.py collectstatic --no-input

# django_app to be replaced if needed
gunicorn django_project.wsgi:application --bind "0.0.0.0:8000"
