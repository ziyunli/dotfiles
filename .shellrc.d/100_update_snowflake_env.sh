#!/bin/bash

# Sourcing $FILE that houses a script that will allow users to set or update their snowflake env vars

# Path to the script in carrot
FILE="$CARROT_DIR/infra/local/script/bento_create_snowflake_envs.sh"

# If file exist, source the file
if [ -f "$FILE" ]; then
  source $FILE
fi
