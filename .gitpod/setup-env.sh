# Initialize variables to get Moodle code.
if [ -z "$MOODLE_REPOSITORY" ];
then
    export MOODLE_REPOSITORY=https://github.com/moodle/moodle.git
fi
if [ -z "$MOODLE_BRANCH" ];
then
    export MOODLE_BRANCH=main
fi

# Clone Moodle repository.
cd "${GITPOD_REPO_ROOT}" && git clone --branch "${MOODLE_BRANCH}" --single-branch "${MOODLE_REPOSITORY}" moodle
