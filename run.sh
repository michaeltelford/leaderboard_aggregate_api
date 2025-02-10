#!/bin/bash

nohup bundle exec rake serve > server.log 2>&1 &
