#Set-PSDebug -Trace 1

if (!$ENV:MOODLE_DOCKER_WWWROOT) {
    echo Error: MOODLE_DOCKER_WWWROOT is not set or not an existing directory
    exit 1
}

if (!$ENV:MOODLE_DOCKER_DB) {
    echo Error: MOODLE_DOCKER_DB is not set
    exit 1
}

$BASEDIR='$pwd'
$ASSETDIR='$BASEDIR\assets'

$COMPOSE_CONVERT_WINDOWS_PATHS=$TRUE

$DOCKERCOMPOSE="docker-compose -f $BASEDIR\base.yml"
$DOCKERCOMPOSE="$DOCKERCOMPOSE -f $BASEDIR\service.mail.yml"

# PHP Version.
if (!$ENV:MOODLE_DOCKER_PHP_VERSION) {
    $ENV:MOODLE_DOCKER_PHP_VERSION=7.2
}

# Database flavour
if ($ENV:MOODLE_DOCKER_DB -ne 'pgsql') {
    $DOCKERCOMPOSE="$DOCKERCOMPOSE -f $BASEDIR\db.$ENV:MOODLE_DOCKER_DB.yml"
}

# Support PHP version overrides for DB..
$filename="$BASEDIR\db.$ENV:MOODLE_DOCKER_DB.$ENV:MOODLE_DOCKER_PHP_VERSION.yml".replace('..yml', '.yml')
if (Test-Path $filename) {
    $DOCKERCOMPOSE="$DOCKERCOMPOSE -f $filename"
}

# Selenium browser
if ($ENV:MOODLE_DOCKER_BROWSER -ne "") {
    if ("$ENV:MOODLE_DOCKER_BROWSER" -ne "firefox") {
        $DOCKERCOMPOSE="$DOCKERCOMPOSE -f $BASEDIR\selenium.$ENV:MOODLE_DOCKER_BROWSER.yml"
    }
}

# Selenium VNC port
$ENV:MOODLE_DOCKER_SELENIUM_SUFFIX=""
$has_ip = $ENV:MOODLE_DOCKER_SELENIUM_VNC_PORT -match '^.*:\d*$'
if ($has_ip -Or ([Int32]::TryParse($ENV:MOODLE_DOCKER_SELENIUM_VNC_PORT,[ref]"") -And $ENV:MOODLE_DOCKER_SELENIUM_VNC_PORT -gt 0)) {
	# If no bind ip has been configured (bind_ip:port), default to 127.0.0.1
    if(!$has_ip) {
		$ENV:MOODLE_DOCKER_SELENIUM_VNC_PORT = '127.0.0.1:'+$ENV:MOODLE_DOCKER_SELENIUM_VNC_PORT
	}

    $ENV:MOODLE_DOCKER_SELENIUM_SUFFIX='-debug'
    $DOCKERCOMPOSE="$DOCKERCOMPOSE -f $BASEDIR\selenium.debug.yml"
}

# External services
if ($ENV:MOODLE_DOCKER_PHPUNIT_EXTERNAL_SERVICES -ne "") {
    $DOCKERCOMPOSE="$DOCKERCOMPOSE -f $BASEDIR\phpunit-external-services.yml"
}

# Webserver host
if (!$ENV:MOODLE_DOCKER_WEB_HOST) {
    $ENV:MOODLE_DOCKER_WEB_HOST='localhost'
}

# Webserver port
if (!$ENV:MOODLE_DOCKER_WEB_PORT) {
    $ENV:MOODLE_DOCKER_WEB_PORT=8000
}

$has_ip = $ENV:MOODLE_DOCKER_WEB_PORT -match '^.*:\d*$'
if ($has_ip -Or ([Int32]::TryParse($ENV:MOODLE_DOCKER_WEB_PORT,[ref]"") -And $ENV:MOODLE_DOCKER_WEB_PORT -gt 0)) {
    # If no bind ip has been configured (bind_ip:port), default to 127.0.0.1
	if(!$has_ip) {
		$ENV:MOODLE_DOCKER_WEB_PORT = '127.0.0.1:'+$ENV:MOODLE_DOCKER_WEB_PORT
	}

    $DOCKERCOMPOSE="$DOCKERCOMPOSE -f $BASEDIR\webserver.port.yml"
}



$joinedargs=$args -Join ' '

iex "$DOCKERCOMPOSE $joinedargs"
