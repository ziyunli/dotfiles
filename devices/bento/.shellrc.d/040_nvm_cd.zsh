# shellcheck shell=bash
# Adds a hook to `cd` so that it runs nvm when necessary. In normal use this is quite fast. If you land
# in a directory that has a new nvm version it'll be a bit slow as it switches to that version.

autoload -U add-zsh-hook
load-nvmrc() {
  if [[ $DISABLE_AUTO_NVM == "true" ]]; then
    return
  fi

  local nvmrc_path="$(nvm_find_nvmrc)"
  disable_message="To disable automatic nvm switching, run \`disable_auto_nvm\`"
  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
      echo "$disable_message"
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
      echo "$disable_message"
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
    echo "$disable_message"
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc