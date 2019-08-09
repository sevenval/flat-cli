# FLAT cli

This repository contains the `flat` command line interface.

It is a shell wrapper that uses the docker image
[`sevenvaltechnologies/flatrunner`](https://hub.docker.com/r/sevenvaltechnologies/flatrunner).

Documentation on FLAT can be found at [sevenval/flat-docs](https://github.com/sevenval/flat-docs)

## Installation

Download the `flat` file and put it into your shell path:

```
$ curl -O https://raw.githubusercontent.com/sevenval/flat-cli/master/flat
$ chmod +x flat
$ mv flat /usr/local/bin
```

(You might need `sudo` or be `root` to execute the last `mv` command).

`flat` cli uses `bash` and `docker`.

## Usage

```
Usage: "$0" [command] [ -p PORT ] [ -d DEBUG ] [ -a ] [ DIRECTORY ]

commands:

start             start flat (uses -p, -d, -a and DIRECTORY)
stop              stop a running flat instance (uses -p and DIRECTORY)
pull              pull latest flatrunner docker image and exit
check-template    check a template from the command line

start params:
-p      Listen port, default: 8080
-d      Debug parameters, default: *:error:log
-a      Output access logs in addition to error logs
DIR     FLAT app directory, default: .

stop params:
-p      Listen port, default: 8080
DIR     FLAT app directory, default: .

check-template params:
FILE    template file
```
