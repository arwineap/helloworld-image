# Helloworld image application

This application will allow an image to be uploaded and shown on the frontpage!

Only the most recent image will be shown.

## Local Usage
You can run the app locally using docker

### configuration
Edit `./config/local.json` with your s3_bucket and img_domain

Edit `./docker-compose.yml` with your home directory and AWS_PROFILE
Run the app locally using docker.

### Bootstrap
Bootstrap your DB with
```
docker-compose up mysql -d
```

### Running
Run the app using
```
docker-compose up
```

Setup your initial schema using:
```
docker-compose exec app flask db  
```

Upload a new picture:
http://127.0.0.1:5000/new

View the latest picture:
http://127.0.0.1:5000/

### Schema changes
We use flask-migration to handle migrations in sqlalchemy.

After a schema change in code, generate a migration file by running:
```
flask db migrate
```

Check the new migration file in `app/migrations/versions/${hash}.py`
May need to add default values to new columns, and data migrations

Apply the migrations by running:
```
flask db upgrade
```
