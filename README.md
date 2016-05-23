Plista ChimneyBro - Developer's little helper
=========================================================================

Plista ChimneyBro is a console tool to ease maintaining projects which widely use Composer for managing dependencies.

ChimneyBro updates dependencies, commits and pushes them in a separate branch. This workflow is often lacked in continously built systems.

Requirements
------------
1. ChimneyBro uses [Bash scripting language](https://www.gnu.org/software/bash/).
2. ChimneyBro is only tested in Linux.
3. ChimneyBro maintains only projects that have [Composer](https://getcomposer.org/) installed and configured.
4. Composer must be [installed globally](https://getcomposer.org/doc/00-intro.md#globally), so be available to execute just as `composer ...` (without a full path).
5. In the current implementation ChimneyBro requires the "[composer-changelogs](https://github.com/pyrech/composer-changelogs)" plugin to be installed in your Composer.

Installation
--------------------
1. Download this repository and put to a folder you would like to execute the tool from.
2. Properly configure [Composer](https://getcomposer.org/) and the "[composer-changelogs](https://github.com/pyrech/composer-changelogs)" plugin in your project.
3. Change dir to the parent directory of your project where composer.lock is located.
4. Run `/path/to/chimneyBro/chimneybro.sh` as a bash script.

Usage
-----
```
Usage:
  chimneybro.sh [options]

Options:
  -h, --help                     Display this help message
  -V, --version                  Display this application version
  -p, --push                     Do not ask for confirmation to push the branch with updates.
  -t, --notags                   Do not use hashtags in the commit message subject.
```

What does ChimneyPro do
-----------------------

ChimneyPro executes the following actions step-by-step:

### 1. Preparing repository

```bash
git checkout next
git pull
```

### 2. Installing already linked dependencies

```bash
composer install
```

### 3. Updating dependencies

```bash
composer update
```

### 4. Checking out a branch for a merge request

```bash
git checkout -b ap/update_deps_20160513_1620
```

### 5. Commiting composer.lock

```bash
git commit -m "Update dependencies ..." ./composer.lock
```

### 6. Pushing the changes to origin
At this step ChimneyBro will prompt you if you're ready to push the changes. So if have noticed any problems at this step you can stop and avoid making your changes public. Git will remain on the just created branch.

Propmpting to proceed with pushing can be disabled with "--push" command line option.

```bash
git push
```

### 7. Switching back to the branch 'next'

```bash
git checkout next
```

Authors
-------
ChimneyBro is developed in [plista GmbH](https://www.plista.com/).

License
-------
ChimneyBro is licensed under the Apache 2.0 License - see the LICENSE file for details.

Acknowledgments
---------------
