@ECHO OFF

IF NOT EXIST "%MOODLE_DOCKER_WWWROOT%" (
    ECHO Error: MOODLE_DOCKER_WWWROOT is not set or not an existing directory
    EXIT /B 1
)

IF "%MOODLE_DOCKER_DB%"=="" (
    ECHO Error: MOODLE_DOCKER_DB is not set
    EXIT /B 1
)

PUSHD %cd%
CD %~dp0..
SET BASEDIR=%cd%
POPD
SET ASSETDIR=%BASEDIR%\assets

SET COMPOSE_CONVERT_WINDOWS_PATHS=true

SET DOCKERCOMPOSE=docker-compose -f "%BASEDIR%\base.yml"
SET DOCKERCOMPOSE=%DOCKERCOMPOSE% -f "%BASEDIR%\service.mail.yml"

IF "%MOODLE_DOCKER_PHP_VERSION%"=="" (
    SET MOODLE_DOCKER_PHP_VERSION=8.1
)

SET DOCKERCOMPOSE=%DOCKERCOMPOSE% -f "%BASEDIR%\db.%MOODLE_DOCKER_DB%.yml"

SET filenamedbversion=%BASEDIR%\db.%MOODLE_DOCKER_DB%.%MOODLE_DOCKER_DB_VERSION%.yml
IF EXIST "%filenamedbversion%" (
    SET DOCKERCOMPOSE=%DOCKERCOMPOSE% -f "%filenamedbversion%"
)

REM Support PHP version overrides for DB not available any more.

IF "%MOODLE_DOCKER_DB_PORT%"=="" (
    SET MOODLE_DOCKER_DB_PORT=
) ELSE (
    SET "TRUE="
    IF NOT "%MOODLE_DOCKER_DB_PORT%"=="%MOODLE_DOCKER_DB_PORT::=%" SET TRUE=1
    IF NOT "%MOODLE_DOCKER_DB_PORT%"=="0" SET TRUE=1
    IF DEFINED TRUE (
        REM If no bind ip has been configured (bind_ip:port), default to 127.0.0.1
        IF "%MOODLE_DOCKER_DB_PORT%"=="%MOODLE_DOCKER_DB_PORT::=%" (
            SET MOODLE_DOCKER_DB_PORT=127.0.0.1:%MOODLE_DOCKER_DB_PORT%
        )
        SET filedbport=%BASEDIR%\db.%MOODLE_DOCKER_DB%.port.yml
        IF EXIST "%filedbport%" (
            SET DOCKERCOMPOSE=%DOCKERCOMPOSE% -f "%filedbport%"
        )
    )
)

IF "%MOODLE_DOCKER_APP_RUNTIME%"=="" (
    SET MOODLE_DOCKER_APP_RUNTIME=ionic7
)

REM Guess mobile app node version (only for local app development)
IF "%MOODLE_DOCKER_APP_NODE_VERSION%"=="" (
    IF NOT "%MOODLE_DOCKER_APP_PATH%"=="" (
        SET filenvmrc=%MOODLE_DOCKER_APP_PATH%\.nvmrc
        IF EXIST "%filenvmrc%" (
            SET /p NODE_VERSION=< "%filenvmrc%"
            SET NODE_VERSION=%NODE_VERSION:v=%
            ECHO %NODE_VERSION% | FINDSTR /r "[0-9.]*" >nul 2>&1
            IF ERRORLEVEL 0 (
                SET MOODLE_DOCKER_APP_NODE_VERSION=%NODE_VERSION%
            )
        )
    )
)

REM Guess mobile app port (only when using Docker app images)
IF "%MOODLE_DOCKER_APP_PORT%"=="" (
    IF NOT "%MOODLE_DOCKER_APP_VERSION%"=="" (
        IF "%MOODLE_DOCKER_APP_RUNTIME%"=="ionic5" (
            SET MOODLE_DOCKER_APP_PORT=80
        ) ELSE (
            SET MOODLE_DOCKER_APP_PORT=443
        )
    )
)

REM Guess mobile app protocol
IF "%MOODLE_DOCKER_APP_PROTOCOL%"=="" (
    if "%MOODLE_DOCKER_APP_RUNTIME%"=="ionic5" (
        SET MOODLE_DOCKER_APP_PROTOCOL=http
    ) ELSE (
        SET MOODLE_DOCKER_APP_PROTOCOL=https
    )
)

IF NOT "%MOODLE_DOCKER_BROWSER%"=="" (
    REM Split MOODLE_DOCKER_BROWSER by : to get selenium tag if sepecified
    FOR /f "tokens=1,2 delims=:" %%i in ("%MOODLE_DOCKER_BROWSER%") do (
        SET MOODLE_DOCKER_BROWSER_NAME=%%i
        SET MOODLE_DOCKER_BROWSER_TAG=%%j
    )
)

IF "%MOODLE_DOCKER_BROWSER_NAME%"=="" (
       SET MOODLE_DOCKER_BROWSER_NAME=firefox
)

IF "%MOODLE_DOCKER_BROWSER_TAG%"=="" (
       IF "%MOODLE_DOCKER_BROWSER_NAME%"=="firefox" (
               SET MOODLE_DOCKER_BROWSER_TAG=3
       )
       IF "%MOODLE_DOCKER_BROWSER_NAME%"=="chrome" (
            IF "%MOODLE_DOCKER_APP_RUNTIME%"=="ionic5" (
                SET MOODLE_DOCKER_BROWSER_TAG=3
            ) ELSE (
                SET MOODLE_DOCKER_BROWSER_TAG=120.0
            )
       )
)

IF "%MOODLE_DOCKER_BROWSER_NAME%"=="chrome" (
    IF NOT "%MOODLE_DOCKER_APP_PATH%"=="" (
        SET DOCKERCOMPOSE=%DOCKERCOMPOSE% -f "%BASEDIR%\moodle-app-dev.yml"
    ) ELSE IF NOT "%MOODLE_DOCKER_APP_VERSION%"=="" (
        SET DOCKERCOMPOSE=%DOCKERCOMPOSE% -f "%BASEDIR%\moodle-app.yml"
    )
)

IF NOT "%MOODLE_DOCKER_BROWSER_NAME%"=="firefox" (
       SET DOCKERCOMPOSE=%DOCKERCOMPOSE% -f "%BASEDIR%\selenium.%MOODLE_DOCKER_BROWSER_NAME%.yml"
)

IF NOT "%MOODLE_DOCKER_PHPUNIT_EXTERNAL_SERVICES%"=="" (
    SET DOCKERCOMPOSE=%DOCKERCOMPOSE% -f "%BASEDIR%\phpunit-external-services.yml"
)

IF NOT "%MOODLE_DOCKER_BBB_MOCK%"=="" (
    SET DOCKERCOMPOSE=%DOCKERCOMPOSE% -f "%BASEDIR%\bbb-mock.yml"
)

IF NOT "%MOODLE_DOCKER_MATRIX_MOCK%"=="" (
    SET DOCKERCOMPOSE=%DOCKERCOMPOSE% -f "%BASEDIR%\matrix-mock.yml"
)

IF NOT "%MOODLE_DOCKER_BEHAT_FAILDUMP%"=="" (
    IF NOT EXIST "%MOODLE_DOCKER_BEHAT_FAILDUMP%" (
        ECHO Error: MOODLE_DOCKER_BEHAT_FAILDUMP is not an existing directory
    EXIT /B 1
    )
    SET DOCKERCOMPOSE=%DOCKERCOMPOSE% -f "%BASEDIR%\behat-faildump.yml"
)

IF "%MOODLE_DOCKER_WEB_HOST%"=="" (
    SET MOODLE_DOCKER_WEB_HOST=localhost
)

IF "%MOODLE_DOCKER_WEB_PORT%"=="" (
    SET MOODLE_DOCKER_WEB_PORT=8000
)

SET "TRUE="
IF NOT "%MOODLE_DOCKER_WEB_PORT%"=="%MOODLE_DOCKER_WEB_PORT::=%" SET TRUE=1
IF NOT "%MOODLE_DOCKER_WEB_PORT%"=="0" SET TRUE=1
IF DEFINED TRUE (
    REM If no bind ip has been configured (bind_ip:port), default to 127.0.0.1
    IF "%MOODLE_DOCKER_WEB_PORT%"=="%MOODLE_DOCKER_WEB_PORT::=%" (
        SET MOODLE_DOCKER_WEB_PORT=127.0.0.1:%MOODLE_DOCKER_WEB_PORT%
    )
    SET DOCKERCOMPOSE=%DOCKERCOMPOSE% -f "%BASEDIR%\webserver.port.yml"
)

IF "%MOODLE_DOCKER_SELENIUM_VNC_PORT%"=="" (
    SET MOODLE_DOCKER_SELENIUM_SUFFIX=
) ELSE (
    SET "TRUE="
    IF NOT "%MOODLE_DOCKER_SELENIUM_VNC_PORT%"=="%MOODLE_DOCKER_SELENIUM_VNC_PORT::=%" SET TRUE=1
    IF NOT "%MOODLE_DOCKER_SELENIUM_VNC_PORT%"=="0" SET TRUE=1
    IF DEFINED TRUE (
        IF "%MOODLE_DOCKER_BROWSER_TAG%"=="3" (
            SET MOODLE_DOCKER_SELENIUM_SUFFIX=-debug
        )
        SET DOCKERCOMPOSE=%DOCKERCOMPOSE% -f "%BASEDIR%\selenium.debug.yml"
        REM If no bind ip has been configured (bind_ip:port), default to 127.0.0.1
        IF "%MOODLE_DOCKER_SELENIUM_VNC_PORT%"=="%MOODLE_DOCKER_SELENIUM_VNC_PORT::=%" (
            SET MOODLE_DOCKER_SELENIUM_VNC_PORT=127.0.0.1:%MOODLE_DOCKER_SELENIUM_VNC_PORT%
        )
    )
)


REM Apply local customisations if a local.yml is found.
REM Note: This must be the final modification before the docker-compose command is called.
SET LOCALFILE=%BASEDIR%\local.yml
IF EXIST %LOCALFILE% (
    ECHO Including local options from %localfile%
    SET DOCKERCOMPOSE=%DOCKERCOMPOSE% -f "%LOCALFILE%"
)

%DOCKERCOMPOSE% %*
