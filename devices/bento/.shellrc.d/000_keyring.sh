# shellcheck shell=bash
# Run gnome-keyring-daemon to handle credential storage for ISC

# Kill gnome-keyring-daemon if it was started before the login key was set or updated
# This is to fix an edge case where it started before we copied over a users old keyring and login key
# The daemon would have the wrong key in memory and will fail to unlock the keyring
if pgrep --full gnome-keyring-daemon > /dev/null 2>&1; then
    keyring_start_time=$(stat -c '%Y' "/proc/$(pgrep -f gnome-keyring-daemon)/cmdline")
    key_modified_time=$(stat -c '%Y' "$HOME/.local/share/keyrings/login.key")
    if [[ $keyring_start_time -lt $key_modified_time ]]; then
        killall gnome-keyring-daemon
    fi
fi

# Run only one instance of gnome-keyring-daemon. If there are two it will break.
if ! pgrep --full gnome-keyring-daemon > /dev/null 2>&1; then
    cat "$HOME"/.local/share/keyrings/login.key | gnome-keyring-daemon --unlock --components=secrets
fi