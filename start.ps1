#ref https://github.com/moodlehq/moodle-docker

$ENV:MOODLE_DOCKER_WEB_PORT=8001
$ENV:MOODLE_DOCKER_BROWSER='chrome'

# Set up path to Moodle code
$ENV:MOODLE_DOCKER_WWWROOT="$pwd/../moodle"

# Choose a db server (Currently supported: pgsql, mariadb, mysql, mssql, oracle)
$ENV:MOODLE_DOCKER_DB='pgsql'

# Uncomment and Selenium will expose a VNC session on 127.0.0.1:5900 so behat tests can be viewed in progress.  Password=secret.
#$ENV:MOODLE_DOCKER_SELENIUM_VNC_PORT=5900

# Ensure customized config.php for the Docker containers is in place
cp config.docker-template.php $ENV:MOODLE_DOCKER_WWWROOT/config.php

# Start up containers
./bin/moodle-docker-compose.ps1 up -d

# Wait for DB to come up (important for oracle/mssql)
./bin/moodle-docker-wait-for-db.ps1

# Initialize behat environment
./bin/moodle-docker-compose.ps1 exec webserver php admin/tool/behat/cli/init.php

# Run behat tests
#./bin/moodle-docker-compose.ps1 exec -u www-data webserver php admin/tool/behat/cli/run.php --tags=@auth_manual
#./bin/moodle-docker-compose.ps1 exec -u www-data webserver php admin/tool/behat/cli/run.php --tags=@block_integrityadvocate_quiz

# Stop w/o destroying the container
#bin/moodle-docker-compose.ps1 stop

# Stop and destroy the container
#bin/moodle-docker-compose.ps1 down