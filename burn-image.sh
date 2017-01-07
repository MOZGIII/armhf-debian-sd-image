#!/bin/bash
set -e

if [[ ! -e "$1" || ! -e "$2" ]]; then
  echo >&2 "Usage: $0 from to"
  exit 1
fi

cat "$1" > "$2"
sync
