#!/bin/bash

while read p; do
  echo -n "$p "
done < state/packagelist.txt
