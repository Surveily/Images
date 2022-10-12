FROM python:3.7.14-alpine3.15

WORKDIR /workspace

ENV TZ=Etc/UTC

RUN python3 -m pip install --upgrade pip pymodbus pymodbus[repl]