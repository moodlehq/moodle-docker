# Initialize variables to get Moodle code.
if [ -z "$MOODLE_REPOSITORY" ];
then
    export MOODLE_REPOSITORY=https://github.com/moodle/moodle.git
fi
if [ -z "$MOODLE_BRANCH" ];
then
    export MOODLE_BRANCH=main
fi

if [ -z "$CLONEALL" ];
then
    FASTCLONE='--depth 1'
else
    FASTCLONE=""
fi

# Clone Moodle repository.
cd "${GITPOD_REPO_ROOT}" && git clone ${FASTCLONE} --branch "${MOODLE_BRANCH}" --single-branch "${MOODLE_REPOSITORY}" moodle

# Download the data file (if given). It will be used to generate some data.
if [ -n "$DATAFILE" ];
then
    wget -O moodle/admin/tool/generator/tests/fixtures/gitpod-basic-scenario.feature "${DATAFILE}"
fi

# Install adminer.
if [ -n "$INSTALLADMINER" ];
then
cat << EOF > local.yml
services:

  adminer:
    image: adminer:latest
    restart: always
    ports:
      - 8080:8080
    depends_on:
      - "db"
EOF
fi
