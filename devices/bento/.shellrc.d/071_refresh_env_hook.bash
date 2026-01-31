# shellcheck shell=bash
# See refresh_env_function.sh
if ! [[ "$PROMPT_COMMAND" =~ refresh_env ]]; then
  PROMPT_COMMAND="refresh_env; $PROMPT_COMMAND";
fi