@ECHO OFF

IF "%MOODLE_DOCKER_DB%"=="" (
    ECHO Error: MOODLE_DOCKER_DB is not set
    EXIT /B 1
)

IF "%MOODLE_DOCKER_DB%"=="mssql" (
    CALL "%~dp0moodle-docker-compose.cmd" exec -T db /wait-for-mssql-to-come-up.sh
    EXIT /B %ERRORLEVEL%
)

IF "%MOODLE_DOCKER_DB%"=="oracle" (
    GOTO WAITFORORACLE
)

PING -n 11 127.0.0.1 >NUL
EXIT /B 0

:WAITFORORACLE
CALL "%~dp0moodle-docker-compose.cmd" logs db | FINDSTR /C:"DATABASE IS READY TO USE!" >NUL
IF ERRORLEVEL 1 (
    ECHO Waiting for oracle to come up...
    PING -n 16 127.0.0.1 >NUL
    GOTO WAITFORORACLE
)

EXIT /B 0
