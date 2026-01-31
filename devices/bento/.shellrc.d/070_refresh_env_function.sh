# shellcheck shell=bash
# This function refreshes some env vars that go stale in old tmux sessions
# It must be run as a preexec function in zsh or a PROMPT_COMMAND in bash
function refresh_env {
    local ssh_auth_sock=""
    if [[ -v "TMUX" ]]; then
        ssh_auth_sock=$(tmux show-environment | grep "^SSH_AUTH_SOCK")
    fi
    if [[ -n "$ssh_auth_sock" ]]; then
        #shellcheck disable=SC2163
        export "$ssh_auth_sock"
    fi

    # Try to fix ssh-agent. Sometimes SSH_AUTH_SOCK env var can point to stale/non-existent socket file.
    # This typically happens when the ssh connection restarts.
    if [[ -v "SSH_AUTH_SOCK" && ! -S "$SSH_AUTH_SOCK" ]]; then
      # Check if SSH_AUTH_SOCK is an absolute path
        if [[ "$SSH_AUTH_SOCK" == /* ]]; then
            # Find any valid ssh-agent socket files based on naming pattern
            #shellcheck disable=SC2207
            local sockets=( $(find /tmp -path '/tmp/ssh-*' -name 'agent.*' -type s -user bento 2> /dev/null) )
            for socket in "${sockets[@]}"; do
                if [[ -S "$socket" ]]; then
                    mkdir -p "$(dirname "$SSH_AUTH_SOCK")"
                    ln -sf "$socket" "$SSH_AUTH_SOCK"
                    break
                fi
            done
        fi
    fi
}
