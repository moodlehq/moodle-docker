FROM debian:stretch-slim

RUN apt-get update && apt-get install -my gnupg curl
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -

RUN apt-get clean
RUN apt-get update
RUN apt-get install -y \
        nodejs

RUN /usr/bin/npm install -g grunt-cli
ADD ./bin/start-grunt.sh .
CMD ./start-grunt.sh
