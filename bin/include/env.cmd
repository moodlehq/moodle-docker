@ECHO OFF

IF EXIST "moodle-docker.env" (
    FOR /F "usebackq tokens=1* delims== eol=#" %%i IN (moodle-docker.env) DO (
        IF NOT DEFINED %%i (
           SET %%i=%%j
        )
    )

    IF EXIST "lib/moodlelib.php" (
        IF "%MOODLE_DOCKER_WWWROOT%"=="" (
            SET MOODLE_DOCKER_WWWROOT=%cd%
        )
        IF "%COMPOSE_PROJECT_NAME%"=="" (
            FOR %%* IN (.) DO SET COMPOSE_PROJECT_NAME=%%~nx*
        )
    )
)

IF NOT EXIST "%MOODLE_DOCKER_WWWROOT%" (
    ECHO Error: MOODLE_DOCKER_WWWROOT is not set or not an existing directory
    EXIT /B 1
)

IF "%MOODLE_DOCKER_DB%"=="" (
    ECHO Error: MOODLE_DOCKER_DB is not set
    EXIT /B 1
)
