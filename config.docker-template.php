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
        'browser' => getenv('MOODLE_DOCKER_BROWSER'),
        'wd_host' => 'http://selenium:4444/wd/hub',
        'tags' => '~@_file_upload',
    ),
);

define('PHPUNIT_LONGTEST', true);

if (getenv('MOODLE_DOCKER_PHPUNIT_EXTRAS')) {
    define('TEST_SEARCH_SOLR_HOSTNAME', 'solr');
    define('TEST_SEARCH_SOLR_INDEXNAME', 'test');
    define('TEST_SEARCH_SOLR_PORT', 8983);

    define('TEST_SESSION_REDIS_HOST', 'redis');
    define('TEST_CACHESTORE_REDIS_TESTSERVERS', 'redis');

    define('TEST_CACHESTORE_MONGODB_TESTSERVER', 'mongodb://mongo:27017');

    define('TEST_CACHESTORE_MEMCACHED_TESTSERVERS', "memcached0:11211\nmemcached1:11211");
    define('TEST_CACHESTORE_MEMCACHE_TESTSERVERS', "memcached0:11211\nmemcached1:11211");

    define('TEST_AUTH_LDAP_HOST_URL', 'ldap://ldap');
    define('TEST_AUTH_LDAP_BIND_DN', 'cn=admin,dc=openstack,dc=org');
    define('TEST_AUTH_LDAP_BIND_PW', 'password');
    define('TEST_AUTH_LDAP_DOMAIN', 'ou=Users,dc=openstack,dc=org');

    define('TEST_ENROL_LDAP_HOST_URL', 'ldap://ldap');
    define('TEST_ENROL_LDAP_BIND_DN', 'cn=admin,dc=openstack,dc=org');
    define('TEST_ENROL_LDAP_BIND_PW', 'password');
    define('TEST_ENROL_LDAP_DOMAIN', 'ou=Users,dc=openstack,dc=org');
}

require_once(__DIR__ . '/lib/setup.php');
