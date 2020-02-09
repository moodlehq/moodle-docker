#ref https://github.com/moodlehq/moodle-docker

# Fix clock time drift sync issue ref https://github.com/docker/for-win/issues/5593
Disable-VMIntegrationService -VMName DockerDesktopVM -Name "Time Synchronization"
Enable-VMIntegrationService -VMName DockerDesktopVM -Name "Time Synchronization"

$MANUAL_NOT_BEHAT=0
$DO_STOP=0
$DO_STOP_AND_DESTROY=0

#$ENV:MOODLE_DOCKER_WEB_PORT='127.0.0.1:8001'
$ENV:MOODLE_DOCKER_BROWSER='chrome'

# Set up path to your Moodle code
$ENV:MOODLE_DOCKER_WWWROOT="$pwd/../moodle"

# Choose a db server (Currently supported: pgsql, mariadb, mysql, mssql, oracle)
$ENV:MOODLE_DOCKER_DB='pgsql'

# If set, the selenium node will expose a vnc session on the port specified (e.g. 5900). Similar to MOODLE_DOCKER_WEB_PORT, you can optionally define the host IP to bind to. If you just set the port, VNC binds to 127.0.0.1.  Any integer value (or bind_ip:integer).  Password=secret.
#$ENV:MOODLE_DOCKER_SELENIUM_VNC_PORT=5900

$ENV:MOODLE_DOCKER_PHP_VERSION=7.2
$ENV:MOODLE_DOCKER_PHPUNIT_EXTERNAL_SERVICES="false"

# Ensure customized config.php for the Docker containers is in place
cp config.docker-template.php $ENV:MOODLE_DOCKER_WWWROOT/config.php

# Start up containers
./bin/moodle-docker-compose.ps1 up -d

# Wait for DB to come up (important for oracle/mssql)
./bin/moodle-docker-wait-for-db.ps1

if($MANUAL_NOT_BEHAT) {
	# Initialize Moodle database for manual testing
	./bin/moodle-docker-compose.ps1 exec webserver php admin/cli/install_database.php --agree-license --fullname="Docker moodle" --shortname="docker_moodle" --adminuser=admin --adminpass="test" --adminemail="admin@example.com"

	# Install moosh, setup MooshCourse1, add mooshteacher and mooshstudent, and enrol them.
	docker cp moosh-setup.sh moodle-docker_webserver_1:/var/www/html/;
	docker exec -it moodle-docker_webserver_1 bash /var/www/html/moosh-setup.sh
	
	# Get a shell in the webserver container
	#docker exec -it moodle-docker_webserver_1 bash
	# Example of using Moosh from within the container
	<#
		moosh -n block-add course 2 integrityadvocate course-view-* side-post 0;
		moosh -n course-config-set course 2 enablecompletion 1;
		moosh -n activity-add -n 'moosh test quiz' -o="--intro=\"polite orders.\"" quiz 2
	#>
} else {
	# Initialize behat environment
	./bin/moodle-docker-compose.ps1 exec webserver php admin/tool/behat/cli/init.php

	# Run behat tests
	#./bin/moodle-docker-compose.ps1 exec -u www-data webserver php admin/tool/behat/cli/run.php --tags=@auth_manual
	./bin/moodle-docker-compose.ps1 exec -u www-data webserver php admin/tool/behat/cli/run.php --tags=@block_integrityadvocate
}

IF($DO_STOP) {
	# Stop w/o destroying the container
	./bin/moodle-docker-compose.ps1 stop #OR# the below line
	#docker stop $(docker ps --quiet --filter='name=moodle-')
}

IF($DO_STOP_AND_DESTROY) {
	# Stop and destroy the container
	./bin/moodle-docker-compose.ps1 down #OR# the below line
	#docker stop $(docker ps --quiet --filter='name=moodle-'); docker rm $(docker ps --all --quiet --filter='name=moodle-')
}