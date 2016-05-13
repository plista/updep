#!/bin/bash

# This file is part of Plista ChimneyBro.
#
# (c) plista GmbH
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

UPDATE_COMMIT_SUBJECT='Update dependencies'
UPDATE_COMMIT_TAGS='#upd'
COLOR_NO='\033[0m'
export INFO_STEP_COUNTER=0

function info_exe() {
  echo "\$ $@";
}

function exe() {
  info_exe $@
  "$@"
}

function info_step() {
  local COLOR_GREEN='\033[0;32m'
  local COLOR_YELLOW='\033[33m'

  export INFO_STEP_COUNTER="$((INFO_STEP_COUNTER+1))"
  printf "\n${COLOR_YELLOW}# Chimney.compUp, Step $INFO_STEP_COUNTER. ${COLOR_GREEN}$1${COLOR_NO}\n"
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

function branch_name() {
  local USER_NAME=$(git config --list | grep user.email= | cut -f2 -d'=' | cut -f1 -d'@');
  echo "${USER_NAME}/update_deps_$(date +%Y%m%d_%H%M)";
}

for INPUT_PARAM in "$@"
do
case $INPUT_PARAM in
    --notags|--no-tags)
    PARAM_NOTAGS=1
    shift
    ;;
    --push)
    PUSH_WITHOUT_PROMPT=1
    shift
    ;;
    *)
    die "Unknown parameter '${INPUT_PARAM}'"
    ;;
esac
done

if [[ ! -f ./composer.lock ]]; then
    die 'compose.lock file is not found.' 'This tool can only be run the root folder of your project.'
fi

info_step "Preparing repository"
exe git checkout next && exe git pull

GIT_STATUS="$(git status)"
if [[ $GIT_STATUS == *"Changes not staged for commit:"* ]]; then
  die 'There are uncommited changes.' 'Dependencies can only be updated in a separate commit.'
fi

if git status | grep -q "Your branch is up-to-date with 'origin/next'."; then

  info_step "Installing already linked dependencies"
  exe composer install

  info_step "Updating dependencies"
  info_exe "composer update"

  CHANGELOG_NOTES="$(composer update | awk '/Changelogs summary:/{y=1;next}y' | awk 'NF')"
  if [[ ! $CHANGELOG_NOTES ]]; then
    die 'No updated dependencies detected' 'Note you need to install https://github.com/pyrech/composer-changelogs plugin to Composer'
  fi

  info_step "Checking out a branch for a merge request"
  exe git checkout -b "$(branch_name)"

  info_step "Commiting composer.lock"
  if [[ ! $PARAM_NOTAGS && $UPDATE_COMMIT_TAGS ]]; then
    UPDATE_COMMIT_SUBJECT="${UPDATE_COMMIT_SUBJECT} ${UPDATE_COMMIT_TAGS}"
  fi
  COMMMIT_MESSAGE=$(printf "${UPDATE_COMMIT_SUBJECT}\n\n${CHANGELOG_NOTES}")
  exe git commit -m "${COMMMIT_MESSAGE}" ./composer.lock

  if [[ ! $PUSH_WITHOUT_PROMPT ]]; then
    echo -e "\n\n"
    read -p "Push the changes to origin (y/n)? " -n 1 -r
    if ! [[ $REPLY =~ ^[Yy]$ ]]; then
      printf "\nFinished, but there are unpushed changes.\n\n"
      exit 1
    fi
  fi

  info_step "Pushing the changes to origin"
  exe git push

  info_step "Switching back to the branch 'next'"
  exe git checkout next

  printf "\nFinished.\n\n"

else
  die "The branch 'next' is not up-to-date with the origin."
fi