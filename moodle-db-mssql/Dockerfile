FROM microsoft/mssql-server-linux:ctp2-1

RUN apt-get -y update  && apt-get install -y netcat

ADD root/ /

EXPOSE 1433
CMD /docker-entrypoint.sh
