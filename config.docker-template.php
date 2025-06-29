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

if (getenv('MOODLE_DOCKER_DBTYPE') === 'sqlsrv') {
    $CFG->dboptions['extrainfo'] = [
        // Disable Encryption for now on sqlsrv.
        // It is on by default from msodbcsql18.
        'Encrypt' => false,
    ];
}

if (empty($_SERVER['HTTP_HOST'])) {
    $_SERVER['HTTP_HOST'] = 'localhost';
}
if (strpos($_SERVER['HTTP_HOST'], '.gitpod.io') !== false) {
    // Gitpod.io deployment.
    $CFG->wwwroot   = 'https://' . $_SERVER['HTTP_HOST'];
    $CFG->sslproxy = true;
    // To avoid registration form.
    $CFG->site_is_public = false;
} else {
    // Docker deployment.
    $host = 'localhost';
    if (!empty(getenv('MOODLE_DOCKER_WEB_HOST'))) {
        $host = getenv('MOODLE_DOCKER_WEB_HOST');
    }
    $CFG->wwwroot   = "http://{$host}";
    $port = getenv('MOODLE_DOCKER_WEB_PORT');
    if (!empty($port)) {
        // Extract port in case the format is bind_ip:port.
        $parts = explode(':', $port);
        $port = end($parts);
        if ((string)(int)$port === (string)$port) { // Only if it's int value.
            $CFG->wwwroot .= ":{$port}";
        }
    }
    if (file_exists(__DIR__ . '/public')) {
        // New Moodle 5.1 public directory structure compatibility.
        $CFG->wwwroot .= '/public';
    }
}

$CFG->dataroot  = '/var/www/moodledata';
$CFG->admin     = 'admin';
$CFG->directorypermissions = 0777;
$CFG->smtphosts = 'mailpit:1025';
$CFG->noreplyaddress = 'noreply@example.com';

// Debug options - possible to be controlled by flag in future..
$CFG->debug = (E_ALL); // DEBUG_DEVELOPER
$CFG->debugdisplay = 1;
$CFG->debugstringids = 1; // Add strings=1 to url to get string ids.
$CFG->perfdebug = 15;
$CFG->debugpageinfo = 1;
$CFG->allowthemechangeonurl = 1;
$CFG->passwordpolicy = 0;
$CFG->cronclionly = 0;
$CFG->pathtophp = '/usr/local/bin/php';

$CFG->phpunit_dataroot  = '/var/www/phpunitdata';
$CFG->phpunit_prefix = 't_';
define('TEST_EXTERNAL_FILES_HTTP_URL', 'http://exttests:9000');
define('TEST_EXTERNAL_FILES_HTTPS_URL', 'http://exttests:9000');

$CFG->behat_wwwroot   = 'http://webserver';
if (file_exists(__DIR__ . '/public')) {
    // New Moodle 5.1 public directory structure compatibility.
    $CFG->behat_wwwroot .= '/public';
}

$CFG->behat_dataroot  = '/var/www/behatdata';
$CFG->behat_prefix = 'b_';
$CFG->behat_profiles = array(
    'default' => array(
        'browser' => getenv('MOODLE_DOCKER_BROWSER'),
        'wd_host' => 'http://selenium:4444/wd/hub',
    ),
);
$CFG->behat_faildump_path = '/var/www/behatfaildumps';
$CFG->behat_increasetimeout = getenv('MOODLE_DOCKER_TIMEOUT_FACTOR');

define('PHPUNIT_LONGTEST', true);

if (getenv('MOODLE_DOCKER_APP')) {
    $appport = getenv('MOODLE_DOCKER_APP_PORT') ?: 8100;
    $protocol = getenv('MOODLE_DOCKER_APP_PROTOCOL') ?: 'https';

    $CFG->behat_ionic_wwwroot = "$protocol://moodleapp:$appport";
    $CFG->behat_profiles['default']['capabilities'] = [
        'extra_capabilities' => [
            'chromeOptions' => ['args' => ['--ignore-certificate-errors', '--allow-running-insecure-content']],
        ],
    ];
}

if (getenv('MOODLE_DOCKER_PHPUNIT_EXTRAS')) {
    define('TEST_SEARCH_SOLR_HOSTNAME', 'solr');
    define('TEST_SEARCH_SOLR_INDEXNAME', 'test');
    define('TEST_SEARCH_SOLR_PORT', 8983);

    define('TEST_SESSION_REDIS_HOST', 'redis');
    define('TEST_CACHESTORE_REDIS_TESTSERVERS', 'redis');

    define('TEST_CACHESTORE_MONGODB_TESTSERVER', 'mongodb://mongo:27017');

    define('TEST_CACHESTORE_MEMCACHED_TESTSERVERS', "memcached0:11211\nmemcached1:11211");
    define('TEST_CACHESTORE_MEMCACHE_TESTSERVERS', "memcached0:11211\nmemcached1:11211");

    define('TEST_LDAPLIB_HOST_URL', 'ldap://ldap');
    define('TEST_LDAPLIB_BIND_DN', 'cn=admin,dc=openstack,dc=org');
    define('TEST_LDAPLIB_BIND_PW', 'password');
    define('TEST_LDAPLIB_DOMAIN', 'ou=Users,dc=openstack,dc=org');

    define('TEST_AUTH_LDAP_HOST_URL', 'ldap://ldap');
    define('TEST_AUTH_LDAP_BIND_DN', 'cn=admin,dc=openstack,dc=org');
    define('TEST_AUTH_LDAP_BIND_PW', 'password');
    define('TEST_AUTH_LDAP_DOMAIN', 'ou=Users,dc=openstack,dc=org');

    define('TEST_ENROL_LDAP_HOST_URL', 'ldap://ldap');
    define('TEST_ENROL_LDAP_BIND_DN', 'cn=admin,dc=openstack,dc=org');
    define('TEST_ENROL_LDAP_BIND_PW', 'password');
    define('TEST_ENROL_LDAP_DOMAIN', 'ou=Users,dc=openstack,dc=org');
}

if (property_exists($CFG, 'behat_wwwroot')) {
    $mockhash = sha1($CFG->behat_wwwroot);
} else {
    $mockhash = sha1($CFG->wwwroot);
}

if (getenv('MOODLE_DOCKER_BBB_MOCK')) {
    define('TEST_MOD_BIGBLUEBUTTONBN_MOCK_SERVER', "http://bbbmock/{$mockhash}");
}

if (getenv('MOODLE_DOCKER_MATRIX_MOCK')) {
    define('TEST_COMMUNICATION_MATRIX_MOCK_SERVER', "http://matrixmock/{$mockhash}");
}

if (getenv('MOODLE_DOCKER_MLBACKEND')) {
    define('TEST_MLBACKEND_PYTHON_HOST', 'mlbackendpython');
    define('TEST_MLBACKEND_PYTHON_PORT', 5000);
    define('TEST_MLBACKEND_PYTHON_USERNAME', 'default');
    define('TEST_MLBACKEND_PYTHON_PASSWORD', 'sshhhh');
}

require_once(__DIR__ . '/lib/setup.php');
