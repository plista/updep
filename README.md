# Plista UpDep - Developer's little helper

Plista UpDep is a console tool to ease maintaining projects which widely use Composer for managing dependencies.

UpDep updates dependencies, commits and pushes them in a separate branch. This workflow is often lacked in continously built systems.

## Requirements

1. UpDep uses [Bash scripting language](https://www.gnu.org/software/bash/).
2. UpDep is only tested in Linux.
3. UpDep maintains only projects that have [Composer](https://getcomposer.org/) installed and configured.
4. In the current implementation UpDep requires the "[composer-changelogs](https://github.com/pyrech/composer-changelogs)" plugin to be installed in your Composer.

## Installation

### Installation via Composer

1. Add ``plista-dataeng/updep`` as a dependency to your project's ``composer.json`` file (change version to suit your version of Plista UpDep):
    ```json
        {
            "require": {
                "plista-dataeng/updep": "~1.0"
            }
        }
    ```
2. Download and install Composer:
    ```bash
        curl -s http://getcomposer.org/installer | php
    ```

3. Install your dependencies:
    ```bash
        php composer install --no-dev
    ```

4. Run the program from your project as
    ```bash
        ./vendor/bin/updep.sh
    ```

### Installation via downloading

1. Download this repository and put to a folder you would like to execute the tool from.
2. Properly configure [Composer](https://getcomposer.org/) and the "[composer-changelogs](https://github.com/pyrech/composer-changelogs)" plugin in your project.
3. Go to the parent directory of your project (the one you want to use Plista UpDep for) where composer.lock is located.
4. Run as a bash script:
    ```bash
        /path/to/updep/bin/updep.sh``
    ```        

## Usage

```
Usage:
  updep.sh [options]

Options:
  -h, --help                     Display this help message
  -V, --version                  Display this application version
  -p, --push                     Do not ask for confirmation to push the branch with updates.
  -t, --notags                   Do not use hashtags in the commit message subject.
  --composer                     Use this as a fully-qualified Composer execution command (e.g. "php /usr/local/bin/composer.phar").
                                 If not set the default global "composer" command will be used.
```

## What does Plista UpDep do

UpDep executes the following actions step-by-step:

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
At this step UpDep will prompt you if you're ready to push the changes. So if have noticed any problems at this step you can stop and avoid making your changes public. Git will remain on the just created branch.

Propmpting to proceed with pushing can be disabled with "--push" command line option.

```bash
git push
```

### 7. Switching back to the branch 'next'

```bash
git checkout next
```

### 8. Rolling back dependencies to synchronize the installation with 'next'

```bash
composer install
```

## Authors

UpDep is developed in [plista GmbH](https://www.plista.com/).

## License

UpDep is licensed under the Apache 2.0 License - see the LICENSE file for details.

## Acknowledgments

