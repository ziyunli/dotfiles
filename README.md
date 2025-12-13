# MacOS M1 Laptop

The setup is mainly based on [nix-home](https://github.com/ziyunli/nix-home) while some packages are still depending on Homebrew.

Instead of using `*` to ignore all untracked files in `git status`, I use:

```sh
git config status.showUntrackedFiles no
```

This is to ensure that I don't break tools like ripgrep that can use parent `.gitignore` files to ignore files during search.
