FROM microsoft/mssql-server-linux:ctp-2.0

RUN apt-get -y update  && apt-get install -y netcat

COPY docker-entrypoint.sh /
COPY setup-db-for-moodle.sh /
COPY setup.sql /
RUN chmod +x /setup-db-for-moodle.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 1433
CMD /docker-entrypoint.sh
