# dotfiles-bootstrap

Public entry point for provisioning a wiped Mac from the private
`curare/dotfiles` repository.

Run from Terminal on a fresh Mac:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/curare/dotfiles-bootstrap/main/bootstrap.sh)"
```

Or over SSH:

```sh
ssh -t stas@192.168.8.162 '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/curare/dotfiles-bootstrap/main/bootstrap.sh)"'
```

The script contains no secrets. It installs or prompts for Xcode Command Line
Tools, installs Homebrew, restores the GitHub SSH key from Bitwarden clipboard
or a direct Terminal paste, clones the private repository, and runs its
installer. SSH runs intentionally skip GUI-only work in the private installer;
finish those steps from the Mac console with `cd ~/dotfiles && ./install.sh`.

The canonical source is `public-bootstrap/bootstrap.sh` in the private dotfiles
repository. Publish that file here after changing it.
