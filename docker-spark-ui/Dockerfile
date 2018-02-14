FROM python:2.7-alpine

MAINTAINER a.sevilla@anchormen.nl

COPY ./spark-ui-proxy.py /

ENV SERVER_PORT=80
ENV BIND_ADDR="0.0.0.0"

EXPOSE 80

ENTRYPOINT ["python", "/spark-ui-proxy.py"]
