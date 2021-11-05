#!/bin/bash

# do NOT remove this command
apt-get update

# fill up your additional steps for the package installation
apt-get install -y \
	sysbench && echo "test"

# remove unnecessary build packages for execution
apt-get remove -y gcc build-essential nano git

# clean up the installation
apt-get autoclean -y && apt-get autoremove -y --purge && rm -rf /var/lib/apt/lists/* && rm -rf /var/cache/apk*