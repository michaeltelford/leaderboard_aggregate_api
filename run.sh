#!/bin/bash

# We originally used this command:
# nohup bundle exec rake serve > server.log 2>&1 &

# Now we use:
bundle exec overmind start -D -r all
