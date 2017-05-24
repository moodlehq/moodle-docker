<?php  // Moodle configuration file

unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = getenv('MOODLE_DOCKER_DBTYPE');
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'db';
$CFG->dbname    = getenv('MOODLE_DOCKER_DBNAME');
$CFG->dbuser    = getenv('MOODLE_DOCKER_DBUSER');
$CFG->dbpass    = getenv('MOODLE_DOCKER_DBPASS');
$CFG->prefix    = 'm_';
$CFG->dboptions = ['dbcollation' => getenv('MOODLE_DOCKER_DBCOLLATION')];

$CFG->wwwroot   = 'http://localhost:8000';
$CFG->dataroot  = '/var/www/moodledata';
$CFG->admin     = 'admin';
$CFG->directorypermissions = 0777;

$CFG->phpunit_dataroot  = '/var/www/moodledata/phpunit';
$CFG->phpunit_prefix = 't_';

$CFG->behat_wwwroot   = 'http://webserver';
$CFG->behat_dataroot  = '/var/www/moodledata/behat';
$CFG->behat_prefix = 'b_';
$CFG->behat_profiles = array(
    'default' => array(
        'browser' => 'firefox',
        'wd_host' => 'http://selenium:4444/wd/hub',
        'tags' => '~@_file_upload',
    ),
);

define('PHPUNIT_LONGTEST', true);
require_once(__DIR__ . '/lib/setup.php');
