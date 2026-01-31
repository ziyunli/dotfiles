# shellcheck shell=bash
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
export PYTHONPATH="${PYTHONPATH}:/home/bento/unata-buffet/api:/home/bento/unata-buffet/archetypes:/home/bento/unata-buffet/bokchoy:/home/bento/unata-buffet/entice:/home/bento/unata-buffet/pinata:/home/bento/unata-buffet/potato:/home/bento/unata-buffet/prophet:/home/bento/unata-buffet/tasks:/home/bento/unata-buffet/tofu:/home/bento/unata-buffet/tools"
