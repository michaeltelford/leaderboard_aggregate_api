#!/bin/bash

# nohup bundle exec rake serve > server.log 2>&1 &
# overmind start
nohup overmind start > server.log 2>&1 &
