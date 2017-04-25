FROM microsoft/mssql-server-linux:latest

RUN apt-get -y update  && apt-get install -y netcat

COPY . /
RUN chmod +x /setup-db-for-moodle.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 1433
CMD /docker-entrypoint.sh
