# Systemd

Use `systemd-run` to create a sandbox for VS Code to ensure Copilot (or any
other AI) may not access sensitive environment variables and files.

## Benefits

- AI & other extensions can't access files in your home directory
- The environment will be purified, so extensions can't access sensitive
  environment variables (e.g. tokens, credentials, agent sockets, etc.)
- You can symlink files with sensitive data inside workspaces to outside of
  the workspace, so they are still accessible if you run commands outside of
  VS Code, e.g.:

```sh
# since the sandbox will not have access to the home directory, the symlink will
# be worthless inside the sandbox, but it will work outside of it
ln -s /home/me/.secrets/my-ansible-vault-pw /path/to/workspace/my-ansible-vault-pw
```

## Drawbacks

- Some extensions may not work properly if they rely on access to files in the
  home directory or environment variables (you may need to add additional mounts
  or env vars to the sandbox settings)
- Some extensions only make sense if they have access to secrets (e.g. sops
  or ansible-vault extensions)

## Setup

- Adjust settings.sh if needed (e.g. to point to your vscode executable).
  Have a look at the comments in the file for more details.
- Create the necessary directories

```sh
source settings.sh
mkdir -p "$USERDATA_COMMON" "$SANDBOX_EXTENSIONS"
```

- Populate `$USERDATA_COMMON` with the files you want to share between different
  sandbox instances (e.g. to share Copilot login and settings, add the `User`
  directory from an existing vscode installation here)
- Optionally populate `$SANDBOX_EXTENSIONS` from an existing vscode installation

```sh
ln -sf "$(pwd)/code-daedalus.sh" ~/.local/bin/code-daedalus
```

- Add more files to your sandbox home as you like, e.g. `.zshrc` to have your
  custom shell configuration available in the sandbox

## Usage

- Just run `code-daedalus` in any workspace or provide a path as an argument,
  e.g. `code-daedalus .` or `code-daedalus /path/to/your/project`

## Troubleshooting

- The `--collect` flag of `systemd-run` should take care of clean-up.
- But if it fails you can find the running temporary services with:

```sh
systemctl --user list-units --type=service | grep -i code
```

- The services should be named something like `run-p599604-i599904.service`
- You can stop them with:

```sh
systemctl --user reset-failed run-p599604-i599904.service
systemctl --user stop run-p599604-i599904.service
```

- Or look at the logs with:

```sh
journalctl --user -xefu run-p599604-i599904.service
```
