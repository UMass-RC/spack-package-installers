#!/bin/bash

# USAGE
# ./spack-remove <spack package>

#SPACK_PACKAGE_NAME=$1
SPACK_PACKAGE_NAME=$*

#echo "spack uninstall -all $SPACK_PACKAGE_NAME"
if [$? == 0]; then
	#echo "sed '/$SPACK_PACKAGE_NAME/d' ./state/packagelist.txt"
fi

