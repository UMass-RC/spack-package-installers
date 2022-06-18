#!/bin/bash

while read p; do
  ./install-package $p
  sleep 1
done < installed_packages
