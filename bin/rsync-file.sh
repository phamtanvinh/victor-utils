#!/bin/bash

# Supposed to run on rsync-host01, change rsync-host02 to rsync-host01 to make a script that is meant to run on rsync-host02.

while inotifywait -r -e delete_self -e modify,attrib,close_write,move,create,delete /victor/victor-realtime; do
  rsync -avz --delete /victor/victor-realtime /home/docker
done