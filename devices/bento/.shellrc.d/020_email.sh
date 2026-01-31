# shellcheck shell=bash
if [[ -f "$HOME/.config/bento/email.txt" ]]; then
  MY_INSTACART_EMAIL=$(cat "$HOME/.config/bento/email.txt")
  export MY_INSTACART_EMAIL
fi
