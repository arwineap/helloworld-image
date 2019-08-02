# Helloworld image application

This application will allow an image to be uploaded and shown on the frontpage!

Only the most recent image will be shown.

## Local Usage
You can run the app locally using docker

### configuration
Edit `./config/local.json` with your s3_bucket and img_domain

Edit `./docker-compose.yml` with your home directory and AWS_PROFILE
Run the app locally using docker.

Configuration secrets for non-local should go into kms. Store the encrypted string in the value of the config, then push the config key onto the kms array.
When the config loads, it will decrypt any of the config values which keys are stored in the kms array.

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

View the latest picture, and upload your own:
http://127.0.0.1:5000/

### Schema changes
We use flask-migration to handle migrations in sqlalchemy.

After a schema change in code, generate a migration file by running:
```
docker-compose exec flask db migrate
```

Check the new migration file in `app/migrations/versions/${hash}.py`
May need to add default values to new columns, and data migrations

Apply the migrations by restarting docker-compose or by running:
```
docker-compose exec flask db upgrade
```
