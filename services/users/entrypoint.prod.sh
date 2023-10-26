#!/bin/sh

wait_for_postgres()
{
  echo "Waiting for postgres..."
  while ! nc -z api-db 5432; do
    sleep 0.1
  done
  echo "Postgresql started"
}

db_url="$DATABASE_URL"

case "$db_url" in
  # If running on AWS the database should already be running
  *amazonaws.com*) echo "No need to wait for database" ;;
  *)         wait_for_postgres ;;
esac


python manage.py recreate_db
python manage.py seed_db
gunicorn -b 0.0.0.0:5000 manage:app
