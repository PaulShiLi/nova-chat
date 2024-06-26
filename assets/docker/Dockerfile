FROM python:3.11-slim

SHELL ["/bin/bash", "-c"]

RUN apt-get update

RUN alias python=python3

WORKDIR /var/www/nova-chat

COPY requirements.txt .
RUN pip install -r requirements.txt


ENV DOCKER=true

ENV LISTEN_PORT=8080
EXPOSE 8080
