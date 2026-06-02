# dotfiles-bootstrap

Public entry point for provisioning a wiped Mac from the private
`curare/dotfiles` repository.

Run:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/curare/dotfiles-bootstrap/4c50981cefb41a9ae631611d3a2de535c1b668d4/bootstrap.sh)"
```

The script contains no secrets. It installs Bitwarden when needed, prompts for
the GitHub SSH key stored in Bitwarden, clears the clipboard after restoring the
key, clones the private repository, and runs its installer.

The canonical source is `public-bootstrap/bootstrap.sh` in the private dotfiles
repository. Publish that file here after changing it.
