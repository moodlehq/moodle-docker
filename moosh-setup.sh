#!/bin/bash
set -x

apt-get update; apt-get install -y nano less;

sed -i 's#\$CFG->debugdisplay = 1;#\$CFG->debugdisplay = 0;#g' config.php;
sed -i 's#$CFG = new stdClass();#&\n$CFG->noreplyaddress="noreply@localhost.com";#' config.php;
sed -i 's#$CFG = new stdClass();#&\n$CFG->summary="Moosh site summary";#' config.php;
sed -i 's#$CFG->directorypermissions = 0777;#&\nini_set("error_log", $CFG->dataroot."/log/error.log");#' config.php;

mkdir /var/www/moodledata/log; chmod 777 /var/www/moodledata/log;

curl https://moodle.org/plugins/download.php/20823/moosh_moodle.zip --output moosh.zip; unzip -o -q moosh.zip; rm -f moosh.zip;
cd moosh; php ../composer.phar install; ln -f -s $PWD/moosh.php /usr/local/bin/moosh; cd ..;
sed -i 's#\$blockinstance\->configdata = .*;#&\n        $blockinstance->timecreated = $blockinstance->timemodified = time();#' /var/www/html/moosh/Moosh/Command/Moodle23/Block/BlockAdd.php;

mooshteacher=$(moosh -n user-create --password test --email mooshteacher1@example.com --firstname MooshTeacher --lastname Mooshuser mooshteacher);
mooshstudent1=$(moosh -n user-create --password test --email mooshstudent1@example.com --firstname MooshStudent1 --lastname Mooshuser1 mooshstudent1);
mooshstudent2=$(moosh -n user-create --password test --email mooshstudent2@example.com --firstname MooshStudent2 --lastname Mooshuser2 mooshstudent2);
courseid=$(moosh -n course-create --category 1 --fullname "MooshCourse1" --description "Moosh Course 1" --idnumber "Moosh1" --visible=y shortname);
moosh -n course-enrol -r editingteacher "$courseid" mooshteacher;
moosh -n course-enrol "$courseid" mooshstudent1 mooshstudent2;

moosh -n course-config-set course "$courseid" enablecompletion 1;
moosh -n activity-add -n 'moosh test quiz' -o="--intro=\"Sample test description.\"" quiz "$courseid";
moosh -n block-add course "$courseid" integrityadvocate course-view-* side-post 0;