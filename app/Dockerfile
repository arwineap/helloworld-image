FROM python:3-alpine

WORKDIR /opt

EXPOSE 5000

CMD python app.py

COPY ./ /opt/

RUN apk add --no-cache mariadb-dev gcc musl-dev linux-headers \
    && pip install -r requirements.txt \
    && pip install uwsgi

ENV CONFIG_FILE /opt/config/aws.json

CMD /bin/sh -c "flask db upgrade; uwsgi --http-socket 0.0.0.0:5000 --manage-script-name --mount /=app:application --plugin /usr/lib/uwsgi/python"
