# dotfiles-bootstrap

Public entry point for provisioning a wiped Mac from the private
`curare/dotfiles` repository.

Install the prerequisites first:

```sh
xcode-select --install
```

After the Command Line Tools installer finishes:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  eval "$(/usr/local/bin/brew shellenv)"
fi
[[ -d /Applications/Bitwarden.app ]] || brew install --cask bitwarden
```

Then run:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/curare/dotfiles-bootstrap/18d543857c61cbabdbeeea39da9501ac15990ed4/bootstrap.sh)"
```

The script contains no secrets. It checks the prerequisites, prompts for the
GitHub SSH key stored in Bitwarden, clears the clipboard after restoring the
key, clones the private repository, and runs its installer.

The canonical source is `public-bootstrap/bootstrap.sh` in the private dotfiles
repository. Publish that file here after changing it.
