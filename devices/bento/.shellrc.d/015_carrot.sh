# shellcheck shell=bash
# Default carrot directory
export CARROT_DIR=~/carrot
export PGHOST=localhost
# Tells apps to skip DB migratons
export USING_BENTO=true
# Tells Bento that this is remote, and to do remote-only behaviors
export IS_REMOTE_INSTANCE=true

# Update remote-tracking refs and run Git's threshold-based maintenance.
carrot-maintain() {
    git -C "$CARROT_DIR" fetch --prune --no-auto-maintenance origin &&
        git -C "$CARROT_DIR" maintenance run --auto
}

# Fetch and check out one origin branch without widening the default fetch refspec.
carrot-co() {
    if [ "$#" -ne 1 ]; then
        printf 'usage: carrot-co <branch>\n' >&2
        return 2
    fi

    local branch=$1
    local remote_ref="refs/remotes/origin/$branch"

    git fetch origin "$branch:$remote_ref" || return

    if git show-ref --verify --quiet "refs/heads/$branch"; then
        git switch "$branch"
    else
        git switch -c "$branch" "$remote_ref"
    fi
}
