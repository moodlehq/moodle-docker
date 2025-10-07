#!/usr/bin/env bash

# Define colors for various output messages.
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

help_messages () {
    echo
    echo
    echo -e "${GREEN}Usage:${NC}"
    echo "    Script that can start multiple Moodle instances."
    echo "    ./k1many.sh option folder1 [folder2] [folder3] [--debug]"
    echo
    echo -e "${GREEN}Options:${NC}"
    echo "    --build       Create and start the containers for the passed folders."
    echo "    --destroy     Stop and remove all running containers. All data is lost."
    echo "    --help        Display this message."
    echo "    --restart     Restart all running containers."
    echo "    --start       Start all stopped containers. Needs folder(s) path as well."
    echo "    --stop        Stop all running containers."
    echo "    --debug       Enable verbose debug output for troubleshooting."
    echo
    echo -e "${GREEN}Folders:${NC}"
    echo "    folder1       Folder pointing to first Moodle instance (Mandatory)."
    echo "    [folder2]     Folder pointing to second Moodle instance (optional)."
    echo "    [folder3]     Folder pointing to third Moodle instance (optional)."
    echo
    echo -e "${GREEN}Examples:${NC}"
    echo "    Start three Moodle instances in /home/username/projects/[folder]."
    echo "    In this example, the first Moodle instance will be in /home/username/projects/M405:"
    echo "    ./k1many.sh --build M405 M401 M501 --debug"
    echo "    Start all Moodle instances passed in parameters:"
    echo "    ./k1many.sh --start M405 M401 M501"
    echo "    Stop all running containers:"
    echo "    ./k1many.sh --stop"
    echo "    Stop and destroy all containers and data:"
    echo "    ./k1many.sh --destroy"
    echo
    echo
}

# Decorator to output information message to the user.
# Takes 1 param, the message to be displayed.
info_message() {
    echo
    echo -e "${CYAN}$1${NC}"
    echo
}

# Decorator to output error message to the user.
# Takes 1 param, the message to be displayed.
error_message() {
    echo
    echo -e "${RED}$1${NC}"
    echo
}

# Debug message, only output if DEBUG is true.
# Takes 1 param, the message to be displayed.
debug_message() {
    if [ "$DEBUG" = true ]; then
        echo -e "${CYAN}[DEBUG] $1${NC}"
    fi
}

# Determines Moodle version-specific settings (PHP version, document root, CLI path, DB version).
# Args:
#   $1: Full path to the Moodle folder.
# Sets global variables:
#   MOODLE_DOCKER_PHP_VERSION: PHP version for the Docker image (e.g., 8.3).
#   MOODLE_DOCKER_DB_VERSION: MariaDB version (e.g., 10.6).
#   DOCUMENT_ROOT: Apache DocumentRoot (e.g., /var/www/html/public for Moodle 5.1).
#   CLI_PATH: Path to CLI scripts (e.g., admin/cli/).
#   PLUGIN_PREFIX: Prefix for plugin paths (e.g., /public for Moodle 5.1).
configure_moodle_version() {
    local folder=$1
    local version_file
    local branch
    local grep_output
    # Check for version.php in root or public folder
    if [ -f "${folder}/version.php" ]; then
        version_file="${folder}/version.php"
    elif [ -f "${folder}/public/version.php" ]; then
        version_file="${folder}/public/version.php"
    else
        error_message "version.php not found in ${folder} or ${folder}/public"
        exit 1
    fi
    debug_message "Checking version.php at ${version_file}"
    # Extract $branch from version.php (matches $branch = '[number]';)
    grep_output=$(grep "\$branch\s*=\s*['\"][0-9]\+['\"];" "${version_file}" || true)
    debug_message "grep output: '${grep_output}'"
    branch=$(echo "${grep_output}" | sed -E "s/.*['\"]([0-9]+)['\"];.*/\1/" || true)
    debug_message "Extracted branch: '${branch}'"
    if [ -z "$branch" ]; then
        error_message "Failed to extract branch from ${version_file}"
        exit 1
    fi
    # Default settings (for older Moodle versions).
    MOODLE_DOCKER_PHP_VERSION=8.1
    MOODLE_DOCKER_DB_VERSION=10.2
    DOCUMENT_ROOT="/var/www/html"
    CLI_PATH="admin/cli"
    PLUGIN_PREFIX=""
    # Version-specific settings.
    case "$branch" in
        "501")
            # Moodle 5.1: Requires PHP 8.3, MariaDB 10.11+, DocumentRoot /var/www/html/public.
            MOODLE_DOCKER_PHP_VERSION=8.3
            MOODLE_DOCKER_DB_VERSION=10.11
            DOCUMENT_ROOT="/var/www/html/public"
            CLI_PATH="admin/cli"
            PLUGIN_PREFIX="/public"
            info_message "Detected Moodle 5.1 (branch ${branch}): Using PHP 8.3, MariaDB 10.11, DocumentRoot ${DOCUMENT_ROOT}."
            ;;
        "405")
            # Moodle 4.5: Requires PHP 8.3, MariaDB 10.6+, traditional structure.
            MOODLE_DOCKER_PHP_VERSION=8.3
            MOODLE_DOCKER_DB_VERSION=10.6
            DOCUMENT_ROOT="/var/www/html"
            CLI_PATH="admin/cli"
            PLUGIN_PREFIX=""
            info_message "Detected Moodle 4.5 (branch ${branch}): Using PHP 8.3, MariaDB 10.6."
            ;;
        "401")
            # Moodle 4.1: Requires PHP 8.1, MariaDB 10.4+, traditional structure.
            MOODLE_DOCKER_PHP_VERSION=8.1
            MOODLE_DOCKER_DB_VERSION=10.4
            DOCUMENT_ROOT="/var/www/html"
            CLI_PATH="admin/cli"
            PLUGIN_PREFIX=""
            info_message "Detected Moodle 4.1 (branch ${branch}): Using PHP 8.1, MariaDB 10.4."
            ;;
        *)
            # Default to PHP 8.1 and MariaDB 10.2 for unrecognized or older branches
            info_message "Unrecognized Moodle branch '${branch}' in ${version_file}. Using default PHP 8.1, MariaDB 10.2."
            ;;
    esac
    # Export variables for use in the script.
    export MOODLE_DOCKER_PHP_VERSION
    export MOODLE_DOCKER_DB_VERSION
    export DOCUMENT_ROOT
    export CLI_PATH
    export PLUGIN_PREFIX
}

start_server() {

    # Start the server.
    bin/moodle-docker-compose up -d
    info_message "Started Docker containers for ${COMPOSE_PROJECT_NAME}"
    
    # Sleep for 6 seconds to allow database to come up.
    # sleep 6

    # Just in case there is still some latency.
    bin/moodle-docker-wait-for-db
    info_message "Database is ready for ${COMPOSE_PROJECT_NAME}"
}

start_instances() {

    local projectname=$1

    # Configure Moodle version-specific settings.
    configure_moodle_version "${fullfolderpath}"

    # Start the container and wait for DB.
    start_server
    info_message "${projectname} is available at http://localhost:${MOODLE_DOCKER_WEB_PORT}"
}

build_instances() {

    local projectname=$1
    local folder=$2
    local xdebug_port=${xDebugPort[$iterator]}

    # Configure Moodle version-specific settings.
    configure_moodle_version "${folder}"
    
    # Install tool_excimer plugin on host.
    local plugin_dir="${folder}${PLUGIN_PREFIX}/admin/tool"
    mkdir -p "${plugin_dir}"
    
    # Only clone if the directory doesn't exist.
    if [ ! -d "${plugin_dir}/excimer" ]; then
        git clone https://github.com/catalyst/moodle-tool_excimer.git "${plugin_dir}/excimer" || {
            info_message "Warning: Failed to clone tool_excimer plugin for ${projectname} (directory may already exist)"
        }
    else
        info_message "tool_excimer plugin already exists at ${plugin_dir}/excimer for ${projectname}, skipping clone"
    fi
    info_message "Ensured tool_excimer plugin for ${projectname} at ${plugin_dir}/excimer"
    debug_message "Using port ${MOODLE_DOCKER_WEB_PORT} for ${projectname}"
    
    # Copy the config.php file to the Moodle folder.
    cp config.docker-template.php "${folder}/config.php"
    debug_message "config.php will dynamically set wwwroot to http://localhost:${MOODLE_DOCKER_WEB_PORT} at runtime via env vars"
    
    # Add wwwrootcheck = false to prevent redirect loops.
    echo "\$CFG->wwwrootcheck = false;" >> "${folder}/config.php"
    info_message "Added \$CFG->wwwrootcheck = false to ${folder}/config.php to prevent redirect loops"
    
    # Update XDebug configuration.
    local xdebug_config_file="assets/php/docker-php-ext-xdebug.ini"
    cp "${xdebug_config_file}" "${xdebug_config_file}.bak" || {
        error_message "Failed to backup ${xdebug_config_file}"
        exit 1
    }
    cat > "${xdebug_config_file}" <<EOL
[xdebug]
zend_extension=xdebug
xdebug.mode=debug,develop
xdebug.client_host=host.docker.internal
xdebug.client_port=${xdebug_port}
xdebug.start_with_request=yes
xdebug.log=/var/log/xdebug.log
xdebug.log_level=10
xdebug.idekey=VSCODE
xdebug.discover_client_host=1
EOL
    info_message "Updated XDebug configuration for ${projectname} with port ${xdebug_port}"
    
    # Start the container and wait for DB.
    start_server
    
    # Ensure XDebug log file is writable.
    bin/moodle-docker-compose exec webserver bash -c "mkdir -p /var/log && touch /var/log/xdebug.log && chmod 666 /var/log/xdebug.log" || {
        error_message "Failed to create XDebug log file for ${projectname}"
        exit 1
    }
    info_message "Created and set permissions for XDebug log file for ${projectname}"
    
    # For Moodle 5.1+, update DocumentRoot to /var/www/html/public.
    if [ "${DOCUMENT_ROOT}" = "/var/www/html/public" ]; then
        bin/moodle-docker-compose exec webserver bash -c "
            sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/public|' /etc/apache2/sites-available/000-default.conf &&
            echo '<Directory /var/www/html/public>' >> /etc/apache2/sites-available/000-default.conf &&
            echo '    Options Indexes FollowSymLinks' >> /etc/apache2/sites-available/000-default.conf &&
            echo '    AllowOverride All' >> /etc/apache2/sites-available/000-default.conf &&
            echo '    Require all granted' >> /etc/apache2/sites-available/000-default.conf &&
            echo '</Directory>' >> /etc/apache2/sites-available/000-default.conf &&
            a2enmod rewrite &&
            apache2ctl configtest
        " || {
            error_message "Apache config test failed for ${projectname}"
            exit 1
        }
        bin/moodle-docker-compose restart webserver
        info_message "Restarted webserver after updating DocumentRoot to ${DOCUMENT_ROOT} for ${projectname} and enabled mod_rewrite"
    fi
    
    # Debug checks (optional).
    if [ "$DEBUG" = true ]; then
        debug_message "Verifying Apache DocumentRoot for ${projectname}:"
        bin/moodle-docker-compose exec webserver grep "DocumentRoot" /etc/apache2/sites-available/000-default.conf || echo "DocumentRoot not found"
        debug_message "Verifying PHP version for ${projectname}:"
        bin/moodle-docker-compose exec webserver php -v | grep "PHP ${MOODLE_DOCKER_PHP_VERSION}" || echo "PHP version check failed"
        debug_message "Verifying Apache modules for ${projectname}:"
        bin/moodle-docker-compose exec webserver apache2ctl -M | grep php || echo "PHP module not found"
        debug_message "Verifying key files for ${projectname} in container:"
        bin/moodle-docker-compose exec webserver ls -l /var/www/html/index.php || echo "Root index.php not found"
        bin/moodle-docker-compose exec webserver ls -l /var/www/html/public/index.php || echo "Public index.php not found"
        bin/moodle-docker-compose exec webserver ls -l /var/www/html/public/login/index.php || echo "Public login/index.php not found"
    fi
    
    # Install Excimer PHP extension.
    bin/moodle-docker-compose exec webserver bash -c "pecl channel-update pecl.php.net && pecl install excimer && docker-php-ext-enable excimer" || {
        error_message "Failed to install Excimer for ${projectname}"
        exit 1
    }
    info_message "Installed and enabled Excimer PHP extension for ${projectname}"
    
    # Install Moodle.
    bin/moodle-docker-compose exec webserver php ${CLI_PATH}/install_database.php --agree-license --fullname="${projectname}" --shortname="${projectname}" --summary="${projectname}" --adminpass="test" --adminemail="admin@example.com" || {
        error_message "Failed to install Moodle for ${projectname}"
        exit 1
    }
    
    # Upgrade Moodle to register the tool_excimer plugin.
    bin/moodle-docker-compose exec webserver php ${CLI_PATH}/upgrade.php --non-interactive || {
        error_message "Failed to upgrade Moodle for ${projectname}"
        exit 1
    }
    info_message "Ran Moodle upgrade for ${projectname} to register tool_excimer plugin"
    
    # Enable the tool_excimer plugin.
    bin/moodle-docker-compose exec webserver php ${CLI_PATH}/cfg.php --component=tool_excimer --name=enable --set=1 || {
        error_message "Failed to enable tool_excimer plugin for ${projectname}"
        exit 1
    }
    info_message "Enabled tool_excimer plugin for ${projectname}"
    
    # Install and enable XDebug extension.
    bin/moodle-docker-compose exec webserver bash -c "pecl uninstall xdebug || true && pecl install xdebug && docker-php-ext-enable xdebug" || {
        error_message "Failed to install XDebug for ${projectname}"
        exit 1
    }
    bin/moodle-docker-compose restart webserver
    info_message "Installed and enabled XDebug for ${projectname}"
    
    # Verify XDebug is loaded.
    bin/moodle-docker-compose exec webserver php -i | grep -q xdebug && info_message "XDebug is loaded for ${projectname}" || {
        error_message "XDebug failed to load for ${projectname}"
        exit 1
    }
    if [ "$DEBUG" = true ]; then
        debug_message "XDebug configuration for ${projectname}:"
        bin/moodle-docker-compose exec webserver php -i | grep -E 'xdebug\.(mode|client_host|client_port|log|log_level|idekey|discover_client_host)'
    fi
    
    # Set Moodle configurations.
    local configs=(
        "sessioncookie=${projectname}"
        "coursebinenable=0"
        "backup_general_users=0 component=backup"
        "updateautocheck=0"
        "updatenotifybuilds=0"
        "allowguestmymoodle=0"
        "forcelogin=1"
        "forceloginforprofiles=1"
        "country=CA"
        "defaultcity=Montreal"
        "timezone=America/Toronto"
        "guestloginbutton=0"
        "enableanalytics=0"
        "enablestats=0"
        "categorybinenable=0"
        "allowsearchengines=2"
    )
    for config in "${configs[@]}"; do
        bin/moodle-docker-compose exec webserver php ${CLI_PATH}/cfg.php --name="${config%%=*}" --set="${config#*=}" || {
            error_message "Failed to set config ${config%%=*} for ${projectname}"
            exit 1
        }
    done
    info_message "${projectname} is available at http://localhost:${MOODLE_DOCKER_WEB_PORT}"
}

reset_config_files() {
    rm -f local.yml
    git checkout assets/php/docker-php-ext-xdebug.ini || {
        error_message "Failed to reset assets/php/docker-php-ext-xdebug.ini"
        exit 1
    }
    info_message "Reset configuration files"
}

exists_in_list() {
    LIST=$1
    DELIMITER=$2
    VALUE=$3
    LIST_WHITESPACES=$(echo "$LIST" | tr "$DELIMITER" " ")
    for x in $LIST_WHITESPACES; do
        if [ "$x" = "$VALUE" ]; then
            return 1
        fi
    done
    return 0
}

validate_folder_path() {
    if [ ! -d "${1}" ]; then
        error_message "${1} is not a valid folder."
        help_messages
        exit 1
    fi
}

###################
### Validations ###
if [ $# -eq 0 ]; then
    error_message "No arguments supplied. See help message below."
    help_messages
    exit 1
fi

# Check for debug flag.
DEBUG=false
if [[ " $@ " =~ " --debug " ]]; then
    DEBUG=true
    debug_message "Debug mode enabled"
fi

# Validate number of arguments (1-4, or 5 with --debug).
if [ $# -lt 1 ] || [ $# -gt 5 ]; then
    error_message "Invalid number of arguments passed in. Must be between 1 and 4 arguments (or 5 with --debug)."
    help_messages
    exit 1
fi

# Validate the switch.
list_of_options="--build --destroy --help --restart --stop --start --debug"
SWITCH=$1
if exists_in_list "$list_of_options" " " "$SWITCH"; then
    error_message "Invalid option $SWITCH."
    help_messages
    exit 1
fi

# Display help message if the --help switch is present.
if [ "$SWITCH" = "--help" ]; then
    help_messages
    exit 0
fi

########################
### Global variables ###
# MOODLE_DOCKER_DB          - database used by Moodle - default maria db.
# MOODLE_DOCKER_WWWROOT     - folder where the Moodle code is located.
# MOODLE_DOCKER_PORT        - port (default 8000).
# MOODLE_DOCKER_PHP_VERSION - php version used in Moodle - default 8.1.
# COMPOSE_PROJECT_NAME      - Docker project name - used to identify sites.

# We always use Maria DB for all our Moodle.
export MOODLE_DOCKER_DB=mariadb
cwd=$(dirname "$PWD")
moodleDockerPort=(8000 1234 5678)
xDebugPort=(9003 9004 9005)

# Use the multiple instances local.yml file.
cp local.yml_many local.yml || {
    error_message "Failed to copy local.yml_many to local.yml"
    exit 1
}
info_message "Copied local.yml_many to local.yml"

################################################
### Process switches that don't need options ###
case $SWITCH in
    "--destroy")
        if ! docker ps | grep -q 'moodlehq'; then
            info_message "No containers running. Nothing to shutdown."
            exit 0
        fi
        docker stop $(docker ps -a -q) || {
            error_message "Failed to stop containers"
            exit 1
        }
        docker rm $(docker ps -a -q) || {
            error_message "Failed to remove containers"
            exit 1
        }
        reset_config_files
        info_message "All containers shut down and removed."
        exit 0
        ;;
    "--restart")
        if ! docker ps | grep -q 'moodlehq'; then
            info_message "No containers running. Nothing to restart."
            exit 0
        fi
        docker restart $(docker ps -q) || {
            error_message "Failed to restart containers"
            exit 1
        }
        info_message "All sites restarted."
        exit 0
        ;;
    "--stop")
        if ! docker ps | grep -q 'moodlehq'; then
            info_message "No containers running. Nothing to stop."
            exit 0
        fi
        docker stop $(docker ps -q) || {
            error_message "Failed to stop containers"
            exit 1
        }
        info_message "All sites stopped."
        exit 0
        ;;
esac

#############################################
### Process switches that require options ###

# Ignore first parm passed to the script.
# Skip the --switch to cycle the folders in argument.
shift

iterator=0
for i in "$@"; do
    if [ "$i" = "--debug" ]; then
        continue
    fi
    argfolder="$i"

    # Full system path of the Moodle instance.
    validate_folder_path "${cwd}/${argfolder}"
    fullfolderpath="${cwd}/${argfolder}"
    export MOODLE_DOCKER_WWWROOT=${fullfolderpath}

    # Used to name the project according to the folder name
    # which makes it easier to recognize who is who in Docker.
    projectname="${argfolder}"
    export COMPOSE_PROJECT_NAME=${projectname}
    export MOODLE_DOCKER_WEB_PORT="${moodleDockerPort[$iterator]}"

    # Domain name for web server (defaults to localhost).
    # export MOODLE_DOCKER_WEB_HOST="example.com"
    
    case $SWITCH in
        "--build")
            if [ -n "$(docker ps -f "name=${projectname}-webserver-1" -f "status=running" -q)" ]; then
                error_message "The site ${projectname} is already running! It cannot be re-initialized."
                exit 1
            fi
            build_instances "${projectname}" "${fullfolderpath}"
            ;;
        "--start")
            start_instances "${projectname}"
            ;;
    esac
    iterator=$((iterator + 1))
done
exit 0