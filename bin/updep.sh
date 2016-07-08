#!/bin/bash

# This file is part of Plista UpDep.
#
# (c) plista GmbH
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

UPDATE_COMMIT_SUBJECT='Update dependencies'
UPDATE_COMMIT_TAGS='#upd'
COLOR_NO='\033[0m'
export INFO_STEP_COUNTER=0
PROGRAM_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
COMPOSER_COMMAND="composer"

function info_exe() {
  echo "\$ $@";
}

function exe() {
  info_exe $@
  $@
}

function info_step() {
  local COLOR_GREEN='\033[0;32m'
  local COLOR_YELLOW='\033[33m'

  export INFO_STEP_COUNTER="$((INFO_STEP_COUNTER+1))"
  printf "\n${COLOR_YELLOW}# Plista UpDep, Step $INFO_STEP_COUNTER. ${COLOR_GREEN}$1${COLOR_NO}\n"
}

function die() {
  local COLOR_ERROR='\033[0;31m'
  local COLOR_INFO='\033[1;30m'

  printf "\n${COLOR_ERROR}Error. $1${COLOR_NO}"
  if [[ $2 ]]; then
    printf "\n${COLOR_INFO}$2${COLOR_NO}"
  fi
  printf "\nexit\n\n"
  exit
}

function die_if_service_file_notfound() {
  if [[ ! -f $1 ]]; then
    die "$1 file is not found." "This tool can only be run together with all files of its distributive."
  fi
}

function get_branch_name() {
  local USER_NAME=$(git config --list | grep user.email= | cut -f2 -d'=' | cut -f1 -d'@');
  echo "${USER_NAME}/update_deps_$(date +%Y%m%d_%H%M%S)";
}

function check_composer() {
  export COMPOSER_COMMAND
  if ! $($COMPOSER_COMMAND >/dev/null 2>&1); then
    die "Cannot run composer as \"${COMPOSER_COMMAND}\""
  fi
}

function display_version() {
  die_if_service_file_notfound "${PROGRAM_DIR}/CHANGELOG.md"
  read -r FIRSTLINE < "${PROGRAM_DIR}/CHANGELOG.md"
  echo "Plista UpDep v${FIRSTLINE:4}"
}

function display_help() {
  die_if_service_file_notfound "${PROGRAM_DIR}/USAGE"
  less -FX "${PROGRAM_DIR}/USAGE"
}


for INPUT_PARAM in "$@"
do
case $INPUT_PARAM in
    --notags|-t)
    PARAM_NOTAGS=1
    shift
    ;;
    --push|-p)
    PUSH_WITHOUT_PROMPT=1
    shift
    ;;
    --composer=*)
    COMPOSER_COMMAND="${INPUT_PARAM#*=}"
    shift
    ;;
    --version|-V)
    display_version
    exit 0
    ;;
    --help|-h)
    display_help
    exit 0
    ;;
    *)
    die "Unknown parameter '${INPUT_PARAM}'"
    ;;
esac
done

if [[ ! -f ./composer.lock ]]; then
    die 'compose.lock file is not found.' 'This tool can only be run from the root folder of your project.'
fi

info_step "Preparing repository"
exe git checkout next && exe git pull

GIT_STATUS="$(git status)"
if [[ $GIT_STATUS == *"Changes not staged for commit:"* ]]; then
  die 'There are uncommited changes.' 'Dependencies can only be updated in a separate commit.'
fi

if git status | grep -q "Your branch is up-to-date with 'origin/next'."; then

  check_composer

  info_step "Installing already linked dependencies"
  exe "${COMPOSER_COMMAND} install"

  info_step "Updating dependencies"
  info_exe "${COMPOSER_COMMAND} update"

  CHANGELOG_NOTES="$(${COMPOSER_COMMAND} update | awk '/Changelogs summary:/{y=1;next}y' | awk 'NF')"
  if [[ ! $CHANGELOG_NOTES ]]; then
    die 'No updated dependencies detected' 'Note you need to install https://github.com/pyrech/composer-changelogs plugin to Composer'
  fi

  BRANCH_NAME="$(get_branch_name)"

  info_step "Checking out a branch for a merge request"
  exe git checkout -b "${BRANCH_NAME}"

  info_step "Commiting composer.lock"
  if [[ ! $PARAM_NOTAGS && $UPDATE_COMMIT_TAGS ]]; then
    UPDATE_COMMIT_SUBJECT="${UPDATE_COMMIT_SUBJECT} ${UPDATE_COMMIT_TAGS}"
  fi
  COMMMIT_MESSAGE=$(printf "${UPDATE_COMMIT_SUBJECT}\n\n${CHANGELOG_NOTES}")
  info_exe "git commit -m '${UPDATE_COMMIT_SUBJECT} ...' -- ./composer.lock"
  git commit -m "${COMMMIT_MESSAGE}" -- ./composer.lock

  if [[ ! $PUSH_WITHOUT_PROMPT ]]; then
    echo -e "\n\n"
    read -p "Push the changes to origin (y/n)? " -n 1 -r
    if ! [[ $REPLY =~ ^[Yy]$ ]]; then
      printf "\nFinished, but there are unpushed changes.\n\n"
      exit 1
    fi
  fi

  info_step "Pushing the changes to origin"
  exe git push origin "${BRANCH_NAME}"

  info_step "Switching back to the branch 'next'"
  exe git checkout next

  info_step "Rolling back dependencies to synchronize the installation with 'next'"
  exe "${COMPOSER_COMMAND} install"


  printf "\nFinished.\n\n"

else
  die "The branch 'next' is not up-to-date with the origin."
fi
