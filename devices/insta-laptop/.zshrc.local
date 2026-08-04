# Instacart laptop zsh configuration
# Sources shared config and adds work-machine hooks

# macOS-specific plugin must be set before sourcing shared config.
DEVICE_PLUGINS=(macos)

source ~/.zshrc.common

# Instacart setup owns this profile; keep its generated contents local.
[ -f "$HOME/.instacart_shell_profile" ] && source "$HOME/.instacart_shell_profile"

# BENTO_COMPLETIONS_START
export BENTO_COMPLETIONS_VERSION=2

autoload -U compinit; compinit
source <(bento completion zsh --silent)
export PGHOST=localhost # Set PGHOST to talk to bento postgres

ava-shell () {
	local tmpfile=$(mktemp);
	trap 'rm -f $tmpfile' EXIT;
	if bento ava shell "$@" --result-file $tmpfile; then
		if [ -e "$tmpfile" ]; then
			local fixed_cmd=$(cat $tmpfile);
			print -z "$fixed_cmd";
		fi
	else
		return 1
	fi
};
alias '?a'='ava-shell';		

# BENTO_COMPLETIONS_END

# bun completions
[ -s "/Users/stephenli/.bun/_bun" ] && source "/Users/stephenli/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
