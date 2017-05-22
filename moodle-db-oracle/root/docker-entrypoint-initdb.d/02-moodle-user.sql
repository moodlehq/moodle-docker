conn sys/oracle as sysdba;

-- Setup Moodle user.
ALTER PROFILE DEFAULT LIMIT PASSWORD_LIFE_TIME UNLIMITED;
CREATE USER moodle IDENTIFIED BY "m@0dl3ing";

GRANT CONNECT,RESOURCE,DBA TO moodle;
GRANT CREATE SESSION TO moodle WITH ADMIN OPTION;
GRANT UNLIMITED TABLESPACE TO moodle;
GRANT EXECUTE ON DBMS_LOCK to moodle;
GRANT EXECUTE ON moodlelib to moodle;

-- Why must I do this oracle?
ALTER SYSTEM SET processes=200 scope=spfile;
ALTER DATABASE DATAFILE '/u01/app/oracle/oradata/XE/system.dbf' AUTOEXTEND ON MAXSIZE UNLIMITED;

-- Restart for the process change above to take effect.
SHUTDOWN IMMEDIATE;
STARTUP;
