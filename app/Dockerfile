FROM python:3-alpine

WORKDIR /opt

EXPOSE 5000

CMD python app.py

COPY ./ /opt/

RUN apk add --no-cache mariadb-dev gcc musl-dev linux-headers \
    && pip install -r requirements.txt \
    && pip install uwsgi

CMD uwsgi --http-socket 0.0.0.0:5000 --manage-script-name --mount /=app:application --plugin /usr/lib/uwsgi/python --disable-logging
