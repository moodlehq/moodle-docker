$basedir='$pwd/../'

if (!$ENV:MOODLE_DOCKER_DB) {
    echo Error: MOODLE_DOCKER_DB is not set
    EXIT 1
}

if ($ENV:MOODLE_DOCKER_DB -eq "mssql") {
    iex "$basedir/bin/moodle-docker-compose.ps1 exec -T db /wait-for-mssql-to-come-up.sh"
} elseif ($ENV:MOODLE_DOCKER_DB -eq "oracle") {
    do {
        echo 'Waiting for oracle to come up...'
        sleep 15
    } until (iex "$basedir/bin/moodle-docker-compose logs db" | Select-String -Pattern 'listening on IP')
} else {
    sleep 5
}
