#Set-PSDebug -Trace 1

IF (!$ENV:MOODLE_DOCKER_WWWROOT) {
    echo Error: MOODLE_DOCKER_WWWROOT is not set or not an existing directory
    EXIT 1
}

IF (!$ENV:MOODLE_DOCKER_DB) {
    echo Error: MOODLE_DOCKER_DB is not set
    EXIT 1
}

$BASEDIR='$pwd'
$ASSETDIR='$BASEDIR\assets'

$COMPOSE_CONVERT_WINDOWS_PATHS=$TRUE

$DOCKERCOMPOSE="docker-compose -f $BASEDIR\base.yml"
$DOCKERCOMPOSE="$DOCKERCOMPOSE -f $BASEDIR\service.mail.yml"

# PHP Version.
IF (!$ENV:MOODLE_DOCKER_PHP_VERSION) {
    $ENV:MOODLE_DOCKER_PHP_VERSION=7.2
}

# Database flavour
IF ($ENV:MOODLE_DOCKER_DB -ne 'pgsql') {
    $DOCKERCOMPOSE="$DOCKERCOMPOSE -f $BASEDIR\db.$ENV:MOODLE_DOCKER_DB.yml"
}

# Support PHP version overrides for DB..
$filename="$BASEDIR\db.$ENV:MOODLE_DOCKER_DB.$ENV:MOODLE_DOCKER_PHP_VERSION.yml".replace('..yml', '.yml')
if (Test-Path $filename) {
    $DOCKERCOMPOSE="$DOCKERCOMPOSE -f $filename"
}

# Selenium browser
IF ($ENV:MOODLE_DOCKER_BROWSER -ne "") {
    IF ("$ENV:MOODLE_DOCKER_BROWSER" -ne "firefox") {
        $DOCKERCOMPOSE="$DOCKERCOMPOSE -f $BASEDIR\selenium.$ENV:MOODLE_DOCKER_BROWSER.yml"
    }
}

IF ($ENV:MOODLE_DOCKER_PHPUNIT_EXTERNAL_SERVICES -ne "") {
    $DOCKERCOMPOSE="$DOCKERCOMPOSE -f $BASEDIR\phpunit-external-services.yml"
}

# Webserver host
IF (!$ENV:MOODLE_DOCKER_WEB_HOST) {
    $ENV:MOODLE_DOCKER_WEB_HOST='localhost'
}

# Webserver port
IF (!$ENV:MOODLE_DOCKER_WEB_PORT) {
    $ENV:MOODLE_DOCKER_WEB_PORT=8000
}

IF ($ENV:MOODLE_DOCKER_WEB_PORT -ne 0) {
    $DOCKERCOMPOSE="$DOCKERCOMPOSE -f $BASEDIR\webserver.port.yml"
}

IF (!$ENV:MOODLE_DOCKER_SELENIUM_VNC_PORT) {
    $ENV:MOODLE_DOCKER_SELENIUM_SUFFIX=''
} ELSE {
    $ENV:MOODLE_DOCKER_SELENIUM_SUFFIX='-debug'
    $DOCKERCOMPOSE="$DOCKERCOMPOSE -f $BASEDIR\selenium.debug.yml"
}

$joinedargs=$args -Join ' '

iex "$DOCKERCOMPOSE $joinedargs"
