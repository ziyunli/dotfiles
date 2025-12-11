# shellcheck shell=bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Automatically choose the right version of nvm when changing directories
function disable_auto_nvm() {
  export DISABLE_AUTO_NVM=true
  echo "export DISABLE_AUTO_NVM=true" >> "$HOME/.shellrc.d/039_nvm_flags.sh"
  echo "Disabled automatic nvm switching."
  echo "This is controlled via the DISABLE_AUTO_NVM environment variable which is stored in ~/.shellrc.d/039_nvm_flags.sh"
}