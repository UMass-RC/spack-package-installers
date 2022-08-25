#!/bin/bash

while getopts "a:" option; do
    case $option in
        a) USER_ARCH=$OPTARG;;
    esac
done

packages=$(<state/archlist.txt)

for package in $packages; do
    # if $USER_ARCH is defined
    if [ ! -z ${USER_ARCH+x} ]; then
        ./install-package -w -a $USER_ARCH $package
    else
        ./install-package -w $package
    sleep 1
done < installed_packages
