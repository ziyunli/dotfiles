# shellrc.d

The contents of this directory are copied into ~/shellrc.d, which is considered
to be a Bento-owned directory. In .bashrc and .zshrc, these files are sourced
in lexical order. Files in this directory should always be prefixed with a three
digit number so that their order is explicitly defined, and not subject to
changes to the human readable part of the file name.

There are three file extensions that can be used here:

- `.sh`: Sourced in both .bashrc and .zshrc
- `.bash`: Sourced only in .bashrc
- `.zsh`: Sourced only in .zshrc

Most files should be `.sh`, but occasionally we need to change the behavior for
bash vs zsh.
